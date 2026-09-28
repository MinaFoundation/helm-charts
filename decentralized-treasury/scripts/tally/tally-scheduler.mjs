// Tallies every proposal whose lifecycle has reached cooldown, without an
// operator.
//
// Polls rather than reacting to events. A tally becomes possible when the
// chain crosses a slot boundary, which no event marks, and it never expires,
// so a poll every few minutes loses nothing. The two inputs are already
// served in-cluster: the chain's slot by the daemon, and the proposals
// awaiting a tally by the api's /proposals list.
//
// Each tally shells out to the same CLI commands devops/TESTNET.md runs by
// hand ("Build Vote-Reducer Proof", "Submit The Tally"):
//
//   vote-reducer clear-state       drop the previous proposal's reducer state
//   proposal fetch-actions         read the proposal's votes from the archive
//   vote-reducer trace-run-batch   trace them against the lifecycle's ledger
//   vote-reducer prove-run-batch   prove the batches (the in-pod worker)
//   vote-reducer prove-merge       merge them into one reducer proof
//   proposal tally-votes           submit it with the exhausted staking proof
//
// Proposals are tallied one at a time. The reducer keeps its traces, proofs
// and nullifiers in the lifecycle's SQLite body, keyed by lifecycle and not by
// proposal, so two proposals of one lifecycle cannot be reduced at once.
//
// Nothing here runs more than once per proposal unless it failed. The outcome
// of every attempt is stored under WORK_DIRECTORY/state; see
// tally-selection.mjs for how a failure is retried or given up on.

import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { mkdir, readFile, rename, rm, writeFile } from "node:fs/promises";
import { join } from "node:path";
import {
  anchorLifecycleId,
  failureRecord,
  isAttemptDue,
  selectCandidates,
} from "./tally-selection.mjs";

const API_URL = requireEnv("API_URL");
const MINA_NODE_URL = requireEnv("MINA_NODE_URL");
const SQLITE_DATA_DIRECTORY = requireEnv("SQLITE_DATA_DIRECTORY");
const PROOFS_DIRECTORY = requireEnv("PROOFS_DIRECTORY");
const WORK_DIRECTORY = requireEnv("WORK_DIRECTORY");
const QUEUE_NAME = requireEnv("TALLY_QUEUE_NAME");
const APP_DIRECTORY = process.env.APP_DIRECTORY ?? "/app";
const POLL_INTERVAL_SECONDS = Number(
  process.env.TALLY_POLL_INTERVAL_SECONDS ?? 300,
);
const LIFECYCLE_ANCHOR_GROUP_SIZE = Number(
  process.env.LIFECYCLE_ANCHOR_GROUP_SIZE ?? 1,
);

const CLOCK = {
  treasuryDeployedAtSlot: Number(requireEnv("TREASURY_DEPLOYED_AT_SLOT")),
  lifecyclePeriodDuration: Number(requireEnv("LIFECYCLE_PERIOD_DURATION")),
  periodsPerLifecycle: Number(process.env.PERIODS_PER_LIFECYCLE ?? 4),
  startDelaySlots: Number(process.env.TALLY_START_DELAY_SLOTS ?? 20),
};

const RETRY_POLICY = {
  maxAttempts: Number(process.env.TALLY_MAX_ATTEMPTS ?? 3),
  retryBackoffSeconds: Number(process.env.TALLY_RETRY_BACKOFF_SECONDS ?? 1800),
};

// Keeps the end of each CLI run's output, where o1js reports the assertion
// that failed. That text is what decides whether a failure is terminal.
const OUTPUT_TAIL_BYTES = 64 * 1024;

const STATE_DIRECTORY = join(WORK_DIRECTORY, "state");

let voteReducerCompiled = false;

function requireEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Set ${name}`);
  }
  return value;
}

function log(...args) {
  console.info("[tally-scheduler]", ...args);
}

function sleep(seconds) {
  return new Promise((resolve) => setTimeout(resolve, seconds * 1000));
}

async function currentSlot() {
  const response = await fetch(MINA_NODE_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      query:
        "{ bestChain(maxLength: 1) { protocolState { consensusState { slotSinceGenesis } } } }",
    }),
    signal: AbortSignal.timeout(30_000),
  });
  if (!response.ok) {
    throw new Error(`daemon returned HTTP ${response.status}`);
  }
  const body = await response.json();
  const slot = Number(
    body?.data?.bestChain?.[0]?.protocolState?.consensusState
      ?.slotSinceGenesis,
  );
  if (!Number.isSafeInteger(slot)) {
    throw new Error(`daemon returned no slotSinceGenesis: ${JSON.stringify(body)}`);
  }
  return slot;
}

async function listProposals() {
  const proposals = [];
  let offset = 0;
  while (offset !== null) {
    const url = `${API_URL}/proposals?limit=200&offset=${offset}`;
    const response = await fetch(url, { signal: AbortSignal.timeout(30_000) });
    if (!response.ok) {
      throw new Error(`${url} returned HTTP ${response.status}`);
    }
    const page = await response.json();
    proposals.push(...page.items);
    offset = page.nextOffset;
  }
  return proposals;
}

function statePath(proposalPublicKey) {
  return join(STATE_DIRECTORY, `${proposalPublicKey}.json`);
}

async function readRecord(proposalPublicKey) {
  try {
    return JSON.parse(await readFile(statePath(proposalPublicKey), "utf8"));
  } catch (error) {
    if (error.code === "ENOENT") {
      return null;
    }
    throw error;
  }
}

// Written to a temporary file and renamed, so a restart mid-write never
// leaves a record that fails to parse.
async function writeRecord(record) {
  await mkdir(STATE_DIRECTORY, { recursive: true });
  const target = statePath(record.proposalPublicKey);
  await writeFile(`${target}.part`, `${JSON.stringify(record, null, 2)}\n`);
  await rename(`${target}.part`, target);
}

/**
 * Runs one CLI command and resolves with the tail of its output. Rejects with
 * that tail attached when the command exits non-zero.
 */
function runCli(args) {
  log(`running: mina-treasury ${args.join(" ")}`);
  return new Promise((resolve, reject) => {
    const child = spawn("pnpm", ["run", "cli", "--", ...args], {
      cwd: APP_DIRECTORY,
      env: process.env,
      stdio: ["ignore", "pipe", "pipe"],
    });
    let tail = "";
    const keep = (chunk, stream) => {
      stream.write(chunk);
      tail = (tail + chunk.toString()).slice(-OUTPUT_TAIL_BYTES);
    };
    child.stdout.on("data", (chunk) => keep(chunk, process.stdout));
    child.stderr.on("data", (chunk) => keep(chunk, process.stderr));
    child.on("error", reject);
    child.on("close", (code) => {
      if (code === 0) {
        resolve(tail);
        return;
      }
      const error = new Error(`mina-treasury ${args[0]} ${args[1]} exited ${code}`);
      error.output = tail;
      reject(error);
    });
  });
}

/**
 * The inputs a tally needs from the rest of the stack, or the reason it has
 * to wait for them. Waiting is not a failed attempt: proving the lifecycle
 * takes hours, and the proposal is simply picked up once it is done.
 */
function missingInputs(lifecycleId) {
  const anchor = anchorLifecycleId(lifecycleId, LIFECYCLE_ANCHOR_GROUP_SIZE);
  const body = join(SQLITE_DATA_DIRECTORY, `${lifecycleId}.sqlite`);
  const proven = join(SQLITE_DATA_DIRECTORY, `${anchor}.sqlite.proven`);
  const exhaustedProof = join(PROOFS_DIRECTORY, `${anchor}-exhausted.json`);

  // The .proven marker comes first because it is what guarantees the body is
  // final. proving-scheduler keeps pushing a larger body while it proves, and
  // the cache sync refetches any local body smaller than the remote one - which
  // would delete this pod's reducer state from under a running tally.
  if (!existsSync(proven)) {
    return { reason: `lifecycle ${anchor} is not proven yet` };
  }
  if (!existsSync(exhaustedProof)) {
    return { reason: `${exhaustedProof} has not been mirrored yet` };
  }
  if (!existsSync(body)) {
    return { reason: `${body} is not in the cache` };
  }
  return { exhaustedProof };
}

async function tally(proposal, exhaustedProof) {
  const { proposalPublicKey } = proposal;
  const lifecycleId = String(proposal.lifecycleId);
  const directory = join(WORK_DIRECTORY, "proposals", proposalPublicKey);
  const actionsPath = join(directory, "vote-actions.json");
  const voteReducerProofPath = join(directory, "vote-reducer-proof.json");

  await rm(directory, { recursive: true, force: true });
  await mkdir(directory, { recursive: true });

  if (!voteReducerCompiled) {
    await runCli(["vote-reducer", "compile"]);
    voteReducerCompiled = true;
  }

  await runCli(["vote-reducer", "clear-state", "--lifecycle-id", lifecycleId]);
  await runCli([
    "proposal",
    "fetch-actions",
    "--proposal-public-key",
    proposalPublicKey,
    "--output-path",
    actionsPath,
  ]);

  const { voteActions } = JSON.parse(await readFile(actionsPath, "utf8"));
  if (voteActions.length === 0) {
    return { status: "untallyable", reason: "no votes were cast" };
  }

  await runCli([
    "vote-reducer",
    "trace-run-batch",
    "--lifecycle-id",
    lifecycleId,
    "--vote-actions-path",
    actionsPath,
  ]);
  await runCli([
    "vote-reducer",
    "prove-run-batch",
    "--lifecycle-id",
    lifecycleId,
    "--queue-name",
    QUEUE_NAME,
  ]);
  await runCli([
    "vote-reducer",
    "prove-merge",
    "--lifecycle-id",
    lifecycleId,
    "--queue-name",
    QUEUE_NAME,
    "--proof-output-path",
    voteReducerProofPath,
  ]);
  const output = await runCli([
    "proposal",
    "tally-votes",
    "--proposal-public-key",
    proposalPublicKey,
    "--vote-reducer-proof-path",
    voteReducerProofPath,
    "--staking-ledger-to-voting-ledger-proof-path",
    exhaustedProof,
    "--lifecycle-id",
    lifecycleId,
  ]);
  return { status: "tallied", result: output.slice(-2000) };
}

async function attempt(proposal, previous) {
  const { proposalPublicKey, lifecycleId } = proposal;
  const inputs = missingInputs(Number(lifecycleId));
  if (inputs.reason) {
    log(`waiting to tally ${proposalPublicKey} (lifecycle ${lifecycleId}): ${inputs.reason}`);
    return;
  }

  log(`tallying ${proposalPublicKey} (lifecycle ${lifecycleId})`);
  const startedAt = Date.now();
  let record;
  try {
    const outcome = await tally(proposal, inputs.exhaustedProof);
    record = {
      proposalPublicKey,
      lifecycleId: Number(lifecycleId),
      contractStatusSourceEventId: proposal.contractStatusSourceEventId ?? null,
      attempts: 1,
      updatedAt: new Date().toISOString(),
      ...outcome,
    };
  } catch (error) {
    const output = `${error.message}\n${error.output ?? ""}`;
    record = failureRecord(previous, proposal, output, Date.now(), RETRY_POLICY);
  }
  await writeRecord(record);

  const elapsedSeconds = Math.round((Date.now() - startedAt) / 1000);
  const detail = record.reason ?? record.nextAttemptAt;
  log(
    `${proposalPublicKey}: ${record.status}${detail ? ` (${detail})` : ""} after ${elapsedSeconds}s`,
  );
}

async function cycle() {
  const [slot, proposals] = await Promise.all([currentSlot(), listProposals()]);
  const candidates = selectCandidates(proposals, slot, CLOCK);
  if (candidates.length === 0) {
    log(`slot ${slot}: no proposal is awaiting a tally`);
    return;
  }

  for (const proposal of candidates) {
    const previous = await readRecord(proposal.proposalPublicKey);
    if (!isAttemptDue(previous, proposal, Date.now())) {
      continue;
    }
    await attempt(proposal, previous);
  }
}

async function main() {
  log(
    `api=${API_URL} queue=${QUEUE_NAME} interval=${POLL_INTERVAL_SECONDS}s startDelaySlots=${CLOCK.startDelaySlots} maxAttempts=${RETRY_POLICY.maxAttempts}`,
  );
  while (true) {
    try {
      await cycle();
    } catch (error) {
      log(`cycle failed, retrying in ${POLL_INTERVAL_SECONDS}s: ${error.message}`);
    }
    await sleep(POLL_INTERVAL_SECONDS);
  }
}

await main();

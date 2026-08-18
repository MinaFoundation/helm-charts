// Scales the proving worker Deployment from the depth of the BullMQ queue, so
// the most expensive workload in the stack holds no nodes while there is
// nothing to prove.
//
// Runs as a sidecar next to proving-scheduler rather than as a separate
// workload: the scheduler is what fills the queue, and this needs the same
// redis coordinates it already has.
//
// Deliberately dependency-free. The image ships no Kubernetes client and no
// redis client, so this speaks RESP over a socket and talks to the API server
// with fetch and the projected service account token. Both protocols are used
// here at a depth of two commands and one PATCH, which is not worth an
// image change.
//
// Scaling to zero means each scale-up pays the circuit compile again (~100s
// before the first job runs). That is the trade being made: idle replicas each
// hold 2 CPU / 8Gi, which keeps a node alive for nothing.

import { connect } from "node:net";
import { readFile } from "node:fs/promises";

const QUEUE_NAME = requireEnv("PROVING_QUEUE_NAME");
const REDIS_HOST = requireEnv("REDIS_HOST");
const REDIS_PORT = Number(process.env.REDIS_PORT ?? 6379);
const NAMESPACE = requireEnv("POD_NAMESPACE");
const DEPLOYMENT = requireEnv("WORKER_DEPLOYMENT_NAME");
const MIN_REPLICAS = Number(process.env.AUTOSCALE_MIN_REPLICAS ?? 0);
const MAX_REPLICAS = Number(process.env.AUTOSCALE_MAX_REPLICAS ?? 3);
const POLL_INTERVAL_SECONDS = Number(
  process.env.AUTOSCALE_POLL_INTERVAL_SECONDS ?? 15,
);
const SCALE_DOWN_AFTER_SECONDS = Number(
  process.env.AUTOSCALE_SCALE_DOWN_AFTER_SECONDS ?? 180,
);

const TOKEN_PATH =
  "/var/run/secrets/kubernetes.io/serviceaccount/token";
const API = `https://${process.env.KUBERNETES_SERVICE_HOST}:${
  process.env.KUBERNETES_SERVICE_PORT ?? 443
}`;
// The API server's CA is trusted through NODE_EXTRA_CA_CERTS, set on the
// container: global fetch is undici, which takes no per-request CA option.

function requireEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Set ${name}`);
  }
  return value;
}

function log(...args) {
  console.info("[proving-autoscale]", ...args);
}

/**
 * Runs one or more commands over a single connection and returns the integer
 * replies. Only the `:<n>` reply type is handled, which is all LLEN returns;
 * anything else means the queue keys are not the shape we expect and is worth
 * surfacing rather than coercing to 0.
 */
function redisIntegers(commands) {
  return new Promise((resolve, reject) => {
    const socket = connect({ host: REDIS_HOST, port: REDIS_PORT });
    let buffer = "";

    socket.setTimeout(10_000);
    socket.on("timeout", () => {
      socket.destroy();
      reject(new Error(`redis timed out after 10s`));
    });
    socket.on("error", reject);

    socket.on("connect", () => {
      for (const parts of commands) {
        socket.write(
          `*${parts.length}\r\n` +
            parts.map((p) => `$${p.length}\r\n${p}\r\n`).join(""),
        );
      }
    });

    socket.on("data", (chunk) => {
      buffer += chunk.toString("utf8");
      const lines = buffer.split("\r\n").filter((line) => line.length > 0);
      if (lines.length < commands.length) {
        return;
      }
      socket.end();
      try {
        resolve(
          lines.slice(0, commands.length).map((line) => {
            if (!line.startsWith(":")) {
              throw new Error(`unexpected redis reply: ${line}`);
            }
            return Number(line.slice(1));
          }),
        );
      } catch (error) {
        reject(error);
      }
    });
  });
}

// Jobs not yet finished. `active` is counted as well as `wait` so the last job
// in a batch does not scale its own worker out from under it.
async function pendingJobs() {
  const [waiting, active] = await redisIntegers([
    ["LLEN", `bull:${QUEUE_NAME}:wait`],
    ["LLEN", `bull:${QUEUE_NAME}:active`],
  ]);
  return { waiting, active, pending: waiting + active };
}

async function apiRequest(path, init = {}) {
  // Re-read per call rather than caching: the token is projected and rotated,
  // and a sidecar that outlives its expiry would start 401ing forever.
  const token = await readFile(TOKEN_PATH, "utf8");

  const response = await fetch(`${API}${path}`, {
    ...init,
    headers: {
      Authorization: `Bearer ${token.trim()}`,
      ...(init.headers ?? {}),
    },
  });

  if (!response.ok) {
    throw new Error(
      `${init.method ?? "GET"} ${path} -> ${response.status} ${await response.text()}`,
    );
  }
  return response.json();
}

const SCALE_PATH =
  `/apis/apps/v1/namespaces/${NAMESPACE}/deployments/${DEPLOYMENT}/scale`;

async function currentReplicas() {
  const scale = await apiRequest(SCALE_PATH);
  return scale.spec?.replicas ?? 0;
}

async function setReplicas(replicas) {
  await apiRequest(SCALE_PATH, {
    method: "PATCH",
    headers: { "Content-Type": "application/merge-patch+json" },
    body: JSON.stringify({ spec: { replicas } }),
  });
}

// When the queue first went quiet, or null while there is work.
let emptySince = null;

async function reconcile() {
  const { waiting, active, pending } = await pendingJobs();
  const current = await currentReplicas();

  if (pending > 0) {
    emptySince = null;
    const desired = Math.min(MAX_REPLICAS, Math.max(1, pending));
    // Scale up immediately: work is already queued and waiting on capacity.
    if (desired > current) {
      log(
        `scaling ${DEPLOYMENT} ${current} -> ${desired} (waiting=${waiting} active=${active})`,
      );
      await setReplicas(desired);
    }
    return;
  }

  if (current === MIN_REPLICAS) {
    return;
  }

  // An empty queue does not mean the work is done. proving-scheduler runs
  // prove-digest, then prove-merge, then prove-exhaust against the same
  // lifecycle, and the queue is briefly empty between them while it prepares
  // the next phase. Scaling down into one of those gaps would tear the workers
  // out mid-lifecycle and charge the ~100s circuit compile again moments
  // later, so quiet has to persist before it counts as idle.
  emptySince ??= Date.now();
  const quietFor = Math.round((Date.now() - emptySince) / 1000);
  if (quietFor < SCALE_DOWN_AFTER_SECONDS) {
    return;
  }

  log(
    `scaling ${DEPLOYMENT} ${current} -> ${MIN_REPLICAS} (queue empty for ${quietFor}s)`,
  );
  await setReplicas(MIN_REPLICAS);
  emptySince = null;
}

async function main() {
  log(
    `queue=bull:${QUEUE_NAME} redis=${REDIS_HOST}:${REDIS_PORT} target=${NAMESPACE}/${DEPLOYMENT} range=${MIN_REPLICAS}..${MAX_REPLICAS} interval=${POLL_INTERVAL_SECONDS}s`,
  );

  for (;;) {
    try {
      await reconcile();
    } catch (error) {
      // Never fatal: a transient redis blip or API hiccup must not take the
      // sidecar down and leave the workers stuck at whatever count they had.
      console.error("[proving-autoscale] reconcile failed:", error.message);
    }
    await new Promise((resolve) =>
      setTimeout(resolve, POLL_INTERVAL_SECONDS * 1000),
    );
  }
}

await main();

// Exercises the decisions behind the automated tally. Run it from anywhere:
//
//   node --test decentralized-treasury/tests/tally-selection.test.mjs
//
// What it pins down:
//   * a lifecycle is tallied only once the chain is startDelaySlots into its
//     cooldown, and stays tallyable in every later lifecycle.
//   * only unpaused proposals the API still reports as unknown are picked,
//     oldest lifecycle first.
//   * a fanned-out lifecycle reads its canonical's proof.
//   * a terminal contract assertion is never retried; anything else backs off
//     and gives up after maxAttempts.
//   * a pause and unpause (a new contractStatusSourceEventId) makes a proposal
//     a candidate again, whatever its stored record says.
//   * the cache holds the bodies of proven lifecycles with an attempt still
//     ahead, and no others.
import assert from "node:assert/strict";
import { test } from "node:test";
import {
  anchorLifecycleId,
  cooldownStartSlot,
  failureRecord,
  isAttemptDue,
  isTallyOpen,
  selectCandidates,
  wantedLifecycleIds,
} from "../scripts/tally/tally-selection.mjs";

const CLOCK = {
  treasuryDeployedAtSlot: 1000,
  lifecyclePeriodDuration: 100,
  periodsPerLifecycle: 4,
  startDelaySlots: 5,
};
const POLICY = { maxAttempts: 3, retryBackoffSeconds: 60 };
const NOW = Date.parse("2026-09-28T12:00:00Z");

function proposal(overrides = {}) {
  return {
    proposalPublicKey: "B62qproposal",
    lifecycleId: 0,
    contractStatus: "unknown",
    contractStatusSourceEventId: null,
    isPaused: false,
    createdAtBlockHeight: 10,
    ...overrides,
  };
}

test("cooldown of lifecycle 1 starts after seven periods", () => {
  assert.equal(cooldownStartSlot(1, CLOCK), 1000 + 100 * 7);
});

test("tally opens startDelaySlots into cooldown and never closes", () => {
  const opens = cooldownStartSlot(0, CLOCK) + CLOCK.startDelaySlots;
  assert.equal(isTallyOpen(0, opens - 1, CLOCK), false);
  assert.equal(isTallyOpen(0, opens, CLOCK), true);
  assert.equal(isTallyOpen(0, opens + 100 * 4 * 12, CLOCK), true);
});

test("candidates are unpaused, unknown and open, oldest lifecycle first", () => {
  const slot = cooldownStartSlot(1, CLOCK) + CLOCK.startDelaySlots;
  const picked = selectCandidates(
    [
      proposal({ proposalPublicKey: "later", lifecycleId: 1 }),
      proposal({ proposalPublicKey: "older", lifecycleId: 0, createdAtBlockHeight: 20 }),
      proposal({ proposalPublicKey: "oldest", lifecycleId: 0, createdAtBlockHeight: 5 }),
      proposal({ proposalPublicKey: "paused", isPaused: true }),
      proposal({ proposalPublicKey: "approved", contractStatus: "approved" }),
      proposal({ proposalPublicKey: "voting", lifecycleId: 2 }),
    ],
    slot,
    CLOCK,
  );
  assert.deepEqual(
    picked.map((p) => p.proposalPublicKey),
    ["oldest", "older", "later"],
  );
});

test("a fanned-out lifecycle reads its canonical's proof", () => {
  assert.equal(anchorLifecycleId(7, 1), 7);
  assert.equal(anchorLifecycleId(7, 4), 4);
  assert.equal(anchorLifecycleId(8, 4), 8);
});

test("a terminal assertion is recorded once and never retried", () => {
  const record = failureRecord(
    null,
    proposal(),
    "Error: Participation not met",
    NOW,
    POLICY,
  );
  assert.equal(record.status, "untallyable");
  assert.equal(isAttemptDue(record, proposal(), NOW + 1e12), false);

  const already = failureRecord(null, proposal(), "Vote result already set", NOW, POLICY);
  assert.equal(already.status, "already-tallied");
});

test("other failures back off exponentially, then give up", () => {
  const first = failureRecord(null, proposal(), "ECONNRESET", NOW, POLICY);
  assert.equal(first.status, "retrying");
  assert.equal(first.attempts, 1);
  assert.equal(first.nextAttemptAt, new Date(NOW + 60_000).toISOString());
  assert.equal(isAttemptDue(first, proposal(), NOW), false);
  assert.equal(isAttemptDue(first, proposal(), NOW + 60_000), true);

  const second = failureRecord(first, proposal(), "ECONNRESET", NOW, POLICY);
  assert.equal(second.nextAttemptAt, new Date(NOW + 120_000).toISOString());

  const third = failureRecord(second, proposal(), "ECONNRESET", NOW, POLICY);
  assert.equal(third.status, "gave-up");
  assert.equal(isAttemptDue(third, proposal(), NOW + 1e12), false);
});

test("a new status source event makes a finished proposal a candidate again", () => {
  const tallied = {
    status: "tallied",
    attempts: 1,
    contractStatusSourceEventId: "41",
  };
  assert.equal(
    isAttemptDue(tallied, proposal({ contractStatusSourceEventId: "41" }), NOW),
    false,
  );
  assert.equal(
    isAttemptDue(tallied, proposal({ contractStatusSourceEventId: "57" }), NOW),
    true,
  );

  const gaveUp = failureRecord(
    { ...tallied, status: "gave-up", attempts: 3 },
    proposal({ contractStatusSourceEventId: "57" }),
    "ECONNRESET",
    NOW,
    POLICY,
  );
  assert.equal(gaveUp.attempts, 1);
  assert.equal(gaveUp.status, "retrying");
});

test("wants the bodies of proven lifecycles with an attempt still ahead", () => {
  const candidates = [
    proposal({ proposalPublicKey: "B62qnew", lifecycleId: 11 }),
    proposal({ proposalPublicKey: "B62qsame", lifecycleId: 11 }),
    proposal({ proposalPublicKey: "B62qretrying", lifecycleId: 4 }),
    proposal({ proposalPublicKey: "B62qtallied", lifecycleId: 2 }),
    proposal({ proposalPublicKey: "B62qgaveup", lifecycleId: 3 }),
    proposal({ proposalPublicKey: "B62qunproven", lifecycleId: 13 }),
  ];
  const retrying = failureRecord(null, proposal(), "ECONNRESET", NOW, POLICY);
  const records = new Map([
    ["B62qretrying", retrying],
    ["B62qtallied", { status: "tallied", contractStatusSourceEventId: null }],
    ["B62qgaveup", { status: "gave-up", contractStatusSourceEventId: null }],
  ]);
  const isProven = (lifecycleId) => lifecycleId <= 11;

  assert.deepEqual(wantedLifecycleIds(candidates, records, isProven), [4, 11]);
});

test("wants nothing when no proposal is awaiting a tally", () => {
  assert.deepEqual(wantedLifecycleIds([], new Map(), () => true), []);
});

// Pure decisions for tally-scheduler.mjs: which proposals are due a tally,
// and what a failed attempt means. Nothing here touches the network, the disk
// or a clock of its own, so tests/tally-selection.test.mjs can pin it down.

// The contract's lifecycle has four periods of equal length. Tally opens at
// the start of the fourth, cooldown, and never closes
// (TreasuryOwnerSmartContract.tallyVotes gates on
// requireLifecyclePeriodGreaterThanOrEqual(COOLDOWN, lifecycleId)).
export const COOLDOWN_PERIOD_INDEX = 3;

// Contract assertions that fail the same way on every retry, because the
// inputs they check are fixed once voting has closed. Retrying these only
// burns proving time.
const TERMINAL_FAILURES = [
  { pattern: "Vote result already set", outcome: "already-tallied" },
  { pattern: "Participation not met", outcome: "untallyable" },
  { pattern: "No approval votes cast", outcome: "untallyable" },
];

/**
 * First slot at which lifecycle `lifecycleId` accepts a tally transaction.
 */
export function cooldownStartSlot(lifecycleId, clock) {
  return (
    clock.treasuryDeployedAtSlot +
    clock.lifecyclePeriodDuration *
      (clock.periodsPerLifecycle * lifecycleId + COOLDOWN_PERIOD_INDEX)
  );
}

/**
 * Whether the chain is far enough into cooldown to tally this lifecycle.
 *
 * startDelaySlots holds the tally back after cooldown opens. The first
 * cooldown slot still accepts votes (the contract's range is closed at both
 * ends), and the archive has to have indexed every vote before
 * `proposal fetch-actions` reads them.
 */
export function isTallyOpen(lifecycleId, currentSlot, clock) {
  return (
    currentSlot >= cooldownStartSlot(lifecycleId, clock) + clock.startDelaySlots
  );
}

/**
 * The lifecycle a proposal's staking ledger body and exhausted proof are
 * published under. Only the canonical id of a group is ever built when
 * lifecycles are fanned out; with groupSize 1 this is the id itself.
 */
export function anchorLifecycleId(lifecycleId, groupSize) {
  return lifecycleId - (lifecycleId % groupSize);
}

/**
 * Whether a stored attempt record still describes this proposal.
 *
 * Records are keyed on the API's contractStatusSourceEventId. A pause and
 * unpause sends the contract status back to UNKNOWN, and the API gives it a
 * new source event, so a proposal tallied or given up on before that becomes
 * a candidate again instead of being skipped forever.
 */
export function recordApplies(record, proposal) {
  if (!record) {
    return false;
  }
  return (
    (record.contractStatusSourceEventId ?? null) ===
    (proposal.contractStatusSourceEventId ?? null)
  );
}

/**
 * Whether a proposal should be attempted now, given its stored record.
 */
export function isAttemptDue(record, proposal, nowMs) {
  if (!recordApplies(record, proposal)) {
    return true;
  }
  if (record.status !== "retrying") {
    return false;
  }
  return nowMs >= Date.parse(record.nextAttemptAt);
}

/**
 * Proposals the API reports as awaiting a tally whose lifecycle is open,
 * oldest lifecycle first. Paused proposals are left out: the contract rejects
 * a tally for them.
 */
export function selectCandidates(proposals, currentSlot, clock) {
  return proposals
    .filter((proposal) => proposal.contractStatus === "unknown")
    .filter((proposal) => !proposal.isPaused)
    .filter((proposal) =>
      isTallyOpen(Number(proposal.lifecycleId), currentSlot, clock),
    )
    .sort(
      (a, b) =>
        Number(a.lifecycleId) - Number(b.lifecycleId) ||
        Number(a.createdAtBlockHeight ?? 0) -
          Number(b.createdAtBlockHeight ?? 0),
    );
}

/**
 * The record to store after a failed attempt.
 *
 * A terminal contract assertion ends the proposal at once. Anything else is
 * retried with exponential backoff until maxAttempts, then left as gave-up
 * for an operator to inspect.
 */
export function failureRecord(previous, proposal, output, nowMs, policy) {
  const applies = recordApplies(previous, proposal);
  const attempts = (applies ? previous.attempts : 0) + 1;
  const base = {
    proposalPublicKey: proposal.proposalPublicKey,
    lifecycleId: Number(proposal.lifecycleId),
    contractStatusSourceEventId: proposal.contractStatusSourceEventId ?? null,
    attempts,
    lastError: output.slice(-2000),
    updatedAt: new Date(nowMs).toISOString(),
  };

  const terminal = TERMINAL_FAILURES.find(({ pattern }) =>
    output.includes(pattern),
  );
  if (terminal) {
    return { ...base, status: terminal.outcome, reason: terminal.pattern };
  }
  if (attempts >= policy.maxAttempts) {
    return { ...base, status: "gave-up" };
  }
  const backoffMs = policy.retryBackoffSeconds * 1000 * 2 ** (attempts - 1);
  return {
    ...base,
    status: "retrying",
    nextAttemptAt: new Date(nowMs + backoffMs).toISOString(),
  };
}

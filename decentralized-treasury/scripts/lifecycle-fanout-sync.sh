#!/bin/sh
# EXPERIMENTAL. Fans out one real, fully-proven lifecycle's proofs across the
# rest of its group, so the real build+prove pipeline only ever does the work
# once per group instead of once per synthetic sibling id. See
# lifecycleFanout in values.yaml - this container is only deployed when
# lifecycleFanout.enabled is true, which is never the case for a normal
# release.
#
# A group is LIFECYCLE_FANOUT_GROUP_SIZE consecutive lifecycle ids
# [canonical, canonical+groupSize-1] where canonical % groupSize == 0.
# staking-ledgers-sync.sh, given the same LIFECYCLE_FANOUT_GROUP_SIZE, only
# ever builds a real lifecycle for the canonical id of each group - this
# script is what makes the other ids in the group exist at all.
#
# A sibling gets its own real <id>.sqlite body, relabelled from the
# canonical's. It cannot share the canonical's body by file name: every row
# inside a body is namespaced with the lifecycle id that produced it
# ("staking-ledger-42-accounts:7", "voting-ledger-42-merkle-tree:3-12", ...),
# so a consumer started for the sibling id against the canonical's body finds
# none of its own keys, serves an empty ledger, and every proposal in that
# lifecycle then fails the staking ledger root check. Earlier revisions of this
# script wrote a small <id>.sqlite.alias object instead, which s3-sync-pull.sh
# resolved into a local symlink - cheap, and silently wrong for exactly that
# reason. Relabelling costs one download, one rewrite and one upload of the
# body per sibling, but the expensive part of a lifecycle - the proving - is
# still only ever done once per group, which is what this script is for.
#
# ORDERING MATTERS. A sibling's body and proof JSONs are written
# first, then its .sqlite.proven marker, then its .sqlite.done marker LAST.
# That guarantees a sibling is never visible as "done" - what
# produced_lifecycle_ids() in staking-ledgers-sync.sh, and proving-scheduler's
# own backlog walk, key on - while still unproven or unaliased, which would
# otherwise tempt proving-scheduler into attempting real proving on it:
# exactly the redundant compute this script exists to avoid. It also keeps a
# consumer from downloading a body that is still being uploaded. This
# deliberately reverses the ordering the real producers use (there, .done
# legitimately precedes .proven because two different workloads write them at
# different times; here one writer produces everything, so it can and must
# sequence it the other way around).
set -eu

LIFECYCLE_FANOUT_GROUP_SIZE="${LIFECYCLE_FANOUT_GROUP_SIZE:?Set LIFECYCLE_FANOUT_GROUP_SIZE}"
# Siblings are produced in ascending order, and a body takes minutes, so
# without a floor a mid-group restart spends hours rebuilding lifecycles that
# have already ended before it reaches the one being tested.
LIFECYCLE_FANOUT_MIN_ID="${LIFECYCLE_FANOUT_MIN_ID:-0}"
FANOUT_WORK_DIRECTORY="${FANOUT_WORK_DIRECTORY:-/work}"
SYNC_INTERVAL_SECONDS="${SYNC_INTERVAL_SECONDS:-60}"
SYNC_ONESHOT="${SYNC_ONESHOT:-false}"
NETWORK="${NETWORK:?Set NETWORK}"
SQLITE_S3_PREFIX="s3://${SQLITE_S3_BUCKET:?Set SQLITE_S3_BUCKET}/${NETWORK}"
PROOFS_S3_PREFIX="s3://${PROOFS_S3_BUCKET:?Set PROOFS_S3_BUCKET}/${NETWORK}"

log()      { echo "[lifecycle-fanout-sync] $*"; }
log_warn() { echo "[lifecycle-fanout-sync] WARN $*" >&2; }

# Same convention as produced_lifecycle_ids() in staking-ledgers-sync.sh:
# keyed on the marker, never on the body.
done_ids() {
  aws s3 ls "${SQLITE_S3_PREFIX}/" 2>/dev/null \
    | awk '{ print $4 }' \
    | sed -n 's/^\([0-9][0-9]*\)\.sqlite\.done$/\1/p'
}

proven_ids() {
  aws s3 ls "${SQLITE_S3_PREFIX}/" 2>/dev/null \
    | awk '{ print $4 }' \
    | sed -n 's/^\([0-9][0-9]*\)\.sqlite\.proven$/\1/p'
}

proofs_published() {
  id=$1
  aws s3 ls "${PROOFS_S3_PREFIX}/${id}-exhausted.json" >/dev/null 2>&1 \
    && aws s3 ls "${PROOFS_S3_PREFIX}/${id}-merge.json" >/dev/null 2>&1
}

# Fans out canonical id $1 onto sibling id $2: real (server-side, no
# download/reupload) copies for the small proof JSONs, and a relabelled copy
# of the sqlite body - see the file header for why the body cannot be shared.
duplicate_lifecycle() {
  canonical=$1
  sibling=$2
  body="${FANOUT_WORK_DIRECTORY}/${sibling}.sqlite.part"

  mkdir -p "$FANOUT_WORK_DIRECTORY"
  rm -f "$body"
  log "relabelling lifecycle ${canonical}'s body as ${sibling} (this takes minutes)"
  aws s3 cp "${SQLITE_S3_PREFIX}/${canonical}.sqlite" "$body" --only-show-errors
  python3 /scripts/relabel-lifecycle-sqlite.py "$body" "$canonical" "$sibling"
  aws s3 cp "$body" "${SQLITE_S3_PREFIX}/${sibling}.sqlite" --only-show-errors
  rm -f "$body"

  aws s3 cp "${PROOFS_S3_PREFIX}/${canonical}-exhausted.json" "${PROOFS_S3_PREFIX}/${sibling}-exhausted.json" --only-show-errors
  aws s3 cp "${PROOFS_S3_PREFIX}/${canonical}-merge.json" "${PROOFS_S3_PREFIX}/${sibling}-merge.json" --only-show-errors
  aws s3 cp "${SQLITE_S3_PREFIX}/${canonical}.sqlite.proven" "${SQLITE_S3_PREFIX}/${sibling}.sqlite.proven" --only-show-errors
  aws s3 cp "${SQLITE_S3_PREFIX}/${canonical}.sqlite.done" "${SQLITE_S3_PREFIX}/${sibling}.sqlite.done" --only-show-errors

  log "fanned lifecycle ${canonical} out onto ${sibling}"
}

sync_once() {
  done_set=$(done_ids)
  proven_set=$(proven_ids)

  for canonical in $done_set; do
    [ $(( canonical % LIFECYCLE_FANOUT_GROUP_SIZE )) -eq 0 ] || continue
    echo "$proven_set" | grep -qx "$canonical" || continue

    if ! proofs_published "$canonical"; then
      log_warn "lifecycle ${canonical} is marked proven but its proof JSONs are missing - skipping this cycle"
      continue
    fi

    group_end=$(( canonical + LIFECYCLE_FANOUT_GROUP_SIZE - 1 ))
    sibling=$(( canonical + 1 ))
    while [ "$sibling" -le "$group_end" ]; do
      if [ "$sibling" -lt "$LIFECYCLE_FANOUT_MIN_ID" ]; then
        sibling=$(( sibling + 1 ))
        continue
      fi
      echo "$done_set" | grep -qx "$sibling" || duplicate_lifecycle "$canonical" "$sibling"
      sibling=$(( sibling + 1 ))
    done
  done
}

main() {
  log "sqlite=${SQLITE_S3_PREFIX} proofs=${PROOFS_S3_PREFIX} groupSize=${LIFECYCLE_FANOUT_GROUP_SIZE}"
  [ "$LIFECYCLE_FANOUT_GROUP_SIZE" -gt 1 ] || log_warn "groupSize=1: nothing to duplicate, this container is a no-op"

  if [ "$SYNC_ONESHOT" = "true" ]; then
    sync_once
    log "initial sync complete"
    return 0
  fi

  while true; do
    sync_once || log_warn "sync cycle failed, retrying in ${SYNC_INTERVAL_SECONDS}s"
    sleep "$SYNC_INTERVAL_SECONDS"
  done
}

main

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
# A sibling never gets its own <id>.sqlite body in S3 - only a small
# <id>.sqlite.alias object naming its canonical. s3-sync-pull.sh, run by every
# consumer of the sqlite cache, resolves that alias into a local symlink at
# <id>.sqlite pointing at the canonical's own locally-cached body, so N
# siblings cost one body on disk, not N (a real per-sibling S3 body would cost
# N copies in the bucket and, since every consumer pod keeps its own local
# copy - see the "sidecar gives every pod a real local file" design note - N
# copies again on every single pod that reads it).
#
# ORDERING MATTERS. A sibling's proof JSONs and .sqlite.alias are written
# first, then its .sqlite.proven marker, then its .sqlite.done marker LAST.
# That guarantees a sibling is never visible as "done" - what
# produced_lifecycle_ids() in staking-ledgers-sync.sh, and proving-scheduler's
# own backlog walk, key on - while still unproven or unaliased, which would
# otherwise tempt proving-scheduler into attempting real proving on it:
# exactly the redundant compute this script exists to avoid. This
# deliberately reverses the ordering the real producers use (there, .done
# legitimately precedes .proven because two different workloads write them at
# different times; here one writer produces everything, so it can and must
# sequence it the other way around).
set -eu

LIFECYCLE_FANOUT_GROUP_SIZE="${LIFECYCLE_FANOUT_GROUP_SIZE:?Set LIFECYCLE_FANOUT_GROUP_SIZE}"
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
# download/reupload) copies for the small proof JSONs, but only a pointer
# object for the (potentially large) sqlite body - see the file header.
duplicate_lifecycle() {
  canonical=$1
  sibling=$2

  aws s3 cp "${PROOFS_S3_PREFIX}/${canonical}-exhausted.json" "${PROOFS_S3_PREFIX}/${sibling}-exhausted.json" --only-show-errors
  aws s3 cp "${PROOFS_S3_PREFIX}/${canonical}-merge.json" "${PROOFS_S3_PREFIX}/${sibling}-merge.json" --only-show-errors
  printf '%s' "$canonical" | aws s3 cp - "${SQLITE_S3_PREFIX}/${sibling}.sqlite.alias" --only-show-errors
  aws s3 cp "${SQLITE_S3_PREFIX}/${canonical}.sqlite.proven" "${SQLITE_S3_PREFIX}/${sibling}.sqlite.proven" --only-show-errors
  aws s3 cp "${SQLITE_S3_PREFIX}/${canonical}.sqlite.done" "${SQLITE_S3_PREFIX}/${sibling}.sqlite.done" --only-show-errors

  log "aliased lifecycle ${sibling} onto ${canonical}"
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

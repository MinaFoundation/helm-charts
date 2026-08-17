#!/bin/sh
# Mirrors staking ledger archives from S3 into the directory that
# voting-ledger-scheduler globs.
#
# The bucket already stores them in the scheduler's native layout -
# <network>/<epoch>-<hash>.tar.gz, with a single <epoch>.json member - so this
# is a straight copy with no renaming. That is worth preserving: the scheduler
# parses the epoch as everything before the first dash and skips anything
# non-numeric *without logging*, so a differently named object would leave it
# looking healthy while doing nothing forever.
#
# Only the archives that actually begin a lifecycle are fetched, and only while
# their voting ledger has not been produced yet. Two things make that matter:
# most epochs start no lifecycle at all (one lifecycle spans
# PERIODS_PER_LIFECYCLE of them), and on mainnet a single ledger takes hours to
# process - so mirroring the whole bucket would download hundreds of archives
# that would never be read, and stall pod startup doing it.
#
# An archive is discarded as soon as <lifecycleId>.sqlite exists in the SQLite
# bucket: that object *is* the product, so once it has landed the input has no
# further use. Deliberately keyed on the published object rather than on the
# scheduler's local .done marker, which is written before the push and would
# drop the input while it could still be needed for a retry.
#
# STAKING_LEDGERS_KEEP_LAST_N caps how many unproduced lifecycles are held
# locally at once. The scheduler's poll loop only ever takes the newest, so 1
# is enough to keep it fed; a slightly larger window leaves room to reprocess a
# recent lifecycle by hand. 0 keeps every unproduced lifecycle.

set -eu

STAKING_LEDGERS_DIRECTORY="${STAKING_LEDGERS_DIRECTORY:-/staking-ledgers}"
STAKING_LEDGERS_KEEP_LAST_N="${STAKING_LEDGERS_KEEP_LAST_N:-0}"
SYNC_INTERVAL_SECONDS="${SYNC_INTERVAL_SECONDS:-300}"
SYNC_ONESHOT="${SYNC_ONESHOT:-false}"
LIFECYCLE_PERIOD_DURATION="${LIFECYCLE_PERIOD_DURATION:?Set LIFECYCLE_PERIOD_DURATION}"
TREASURY_DEPLOYED_AT_SLOT="${TREASURY_DEPLOYED_AT_SLOT:-0}"
PERIODS_PER_LIFECYCLE="${PERIODS_PER_LIFECYCLE:-4}"
NETWORK="${NETWORK:?Set NETWORK}"
S3_PREFIX="s3://${STAKING_LEDGERS_S3_BUCKET:?Set STAKING_LEDGERS_S3_BUCKET}/${NETWORK}"
SQLITE_S3_PREFIX="s3://${SQLITE_S3_BUCKET:?Set SQLITE_S3_BUCKET}/${NETWORK}"

# Mirrors deployed_epoch() in the scheduler entrypoint. Both must agree, or the
# sidecar fetches archives the scheduler will not look at.
DEPLOYED_EPOCH=$(( TREASURY_DEPLOYED_AT_SLOT / LIFECYCLE_PERIOD_DURATION ))

log() {
  echo "[s3-sync-staking-ledgers] $*"
}

# Archive filenames in S3, ordered by their leading epoch number.
remote_archives() {
  aws s3 ls "${S3_PREFIX}/" \
    | awk '{ print $4 }' \
    | grep -E '^[0-9]+-.*\.tar\.gz$' \
    | sort -t- -k1,1n
}

# The lifecycle id an epoch begins, or non-zero if it begins none. Same rule as
# lifecycle_id_for_epoch() in the scheduler entrypoint.
lifecycle_id_for_epoch() {
  offset=$(( $1 - DEPLOYED_EPOCH ))
  if [ "$offset" -lt 0 ] || [ $(( offset % PERIODS_PER_LIFECYCLE )) -ne 0 ]; then
    return 1
  fi
  echo $(( offset / PERIODS_PER_LIFECYCLE ))
}

epoch_of() {
  name=${1%.tar.gz}
  echo "${name%%-*}"
}

# Lifecycle ids whose voting ledger is already published, one per line. Listed
# once per cycle rather than probed per archive, which would be an S3 call per
# file on every pass.
produced_lifecycle_ids() {
  aws s3 ls "${SQLITE_S3_PREFIX}/" 2>/dev/null \
    | awk '{ print $4 }' \
    | sed -n 's/^\([0-9][0-9]*\)\.sqlite$/\1/p'
}

# Archives worth having locally: those that begin a lifecycle which has not
# been produced yet, newest first, capped by STAKING_LEDGERS_KEEP_LAST_N.
wanted_archives() {
  produced=$1
  wanted=""

  for name in $(remote_archives); do
    epoch=$(epoch_of "$name")
    lifecycle_id=$(lifecycle_id_for_epoch "$epoch") || continue
    if echo "$produced" | grep -qx "$lifecycle_id"; then
      continue
    fi
    wanted="${wanted}${name}
"
  done

  wanted=$(printf '%s' "$wanted" | grep -v '^$' || true)
  [ -n "$wanted" ] || return 0

  if [ "$STAKING_LEDGERS_KEEP_LAST_N" -gt 0 ]; then
    printf '%s\n' "$wanted" | tail -n "$STAKING_LEDGERS_KEEP_LAST_N"
  else
    printf '%s\n' "$wanted"
  fi
}

# Drops anything not on the wanted list - which covers both the archives whose
# voting ledger has now been published and any left over from an earlier window.
prune_archives() {
  wanted=$1

  for path in "$STAKING_LEDGERS_DIRECTORY"/*.tar.gz; do
    [ -e "$path" ] || continue
    name=$(basename "$path")
    if ! printf '%s\n' "$wanted" | grep -qx "$name"; then
      log "discarding ${name} (voting ledger published, or outside the window)"
      rm -f "$path"
    fi
  done
}

sync_once() {
  mkdir -p "$STAKING_LEDGERS_DIRECTORY"

  produced=$(produced_lifecycle_ids || true)
  wanted=$(wanted_archives "$produced")

  if [ -z "$wanted" ]; then
    log "nothing to fetch: every lifecycle in ${S3_PREFIX} has a voting ledger in ${SQLITE_S3_PREFIX}"
    prune_archives ""
    return 0
  fi

  for name in $wanted; do
    if [ ! -f "${STAKING_LEDGERS_DIRECTORY}/${name}" ]; then
      log "fetching ${name} (lifecycleId=$(lifecycle_id_for_epoch "$(epoch_of "$name")"))"
      aws s3 cp "${S3_PREFIX}/${name}" \
        "${STAKING_LEDGERS_DIRECTORY}/${name}" --only-show-errors
    fi
  done

  prune_archives "$wanted"
}

main() {
  log "source=${S3_PREFIX} dir=${STAKING_LEDGERS_DIRECTORY} keepLastN=${STAKING_LEDGERS_KEEP_LAST_N} deployedEpoch=${DEPLOYED_EPOCH} periodsPerLifecycle=${PERIODS_PER_LIFECYCLE}"

  if [ "$SYNC_ONESHOT" = "true" ]; then
    sync_once
    log "initial sync complete"
    return 0
  fi

  while true; do
    sync_once || log "sync cycle failed, retrying in ${SYNC_INTERVAL_SECONDS}s"
    sleep "$SYNC_INTERVAL_SECONDS"
  done
}

main

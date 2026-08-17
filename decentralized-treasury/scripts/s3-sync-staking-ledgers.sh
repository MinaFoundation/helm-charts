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
# STAKING_LEDGERS_KEEP_LAST_N bounds local disk by keeping the N highest
# epochs. Unlike the SQLite cache this is safe to bound aggressively: the
# scheduler only ever reaches for the epoch matching the lifecycle it is
# processing, and a missing archive is reported explicitly.

set -eu

STAKING_LEDGERS_DIRECTORY="${STAKING_LEDGERS_DIRECTORY:-/staking-ledgers}"
STAKING_LEDGERS_KEEP_LAST_N="${STAKING_LEDGERS_KEEP_LAST_N:-0}"
SYNC_INTERVAL_SECONDS="${SYNC_INTERVAL_SECONDS:-300}"
SYNC_ONESHOT="${SYNC_ONESHOT:-false}"
S3_PREFIX="s3://${STAKING_LEDGERS_S3_BUCKET:?Set STAKING_LEDGERS_S3_BUCKET}/${NETWORK:?Set NETWORK}"

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

retained_archives() {
  if [ "$STAKING_LEDGERS_KEEP_LAST_N" -gt 0 ]; then
    remote_archives | tail -n "$STAKING_LEDGERS_KEEP_LAST_N"
  else
    remote_archives
  fi
}

prune_archives() {
  retained=$1
  [ "$STAKING_LEDGERS_KEEP_LAST_N" -gt 0 ] || return 0

  for path in "$STAKING_LEDGERS_DIRECTORY"/*.tar.gz; do
    [ -e "$path" ] || continue
    name=$(basename "$path")
    if ! echo "$retained" | grep -qx "$name"; then
      log "pruning ${name} (outside keep-last-${STAKING_LEDGERS_KEEP_LAST_N})"
      rm -f "$path"
    fi
  done
}

sync_once() {
  mkdir -p "$STAKING_LEDGERS_DIRECTORY"

  retained=$(retained_archives)

  for name in $retained; do
    if [ ! -f "${STAKING_LEDGERS_DIRECTORY}/${name}" ]; then
      log "fetching ${name}"
      aws s3 cp "${S3_PREFIX}/${name}" \
        "${STAKING_LEDGERS_DIRECTORY}/${name}" --only-show-errors
    fi
  done

  prune_archives "$retained"
}

main() {
  log "source=${S3_PREFIX} dir=${STAKING_LEDGERS_DIRECTORY} keepLastN=${STAKING_LEDGERS_KEEP_LAST_N}"

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

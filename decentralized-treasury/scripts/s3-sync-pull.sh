#!/bin/sh
# Hydrates the local SQLite lifecycle cache from S3 for read-only consumers.
#
# The lifecycle databases are produced by voting-ledger-scheduler and are
# immutable once their .done marker exists, so consumers only ever pull. Two
# rules come straight from how the application uses these files:
#
#   * Markers (.sqlite.done / .sqlite.proven) are never pruned. Both schedulers
#     decide what work remains purely from marker presence, and each marker is
#     a handful of bytes.
#   * Only .sqlite bodies are subject to SQLITE_KEEP_LAST_N, which retains the
#     N highest lifecycle ids. Set it to 0 to keep every body.
#
# Runs one pass and exits when SYNC_ONESHOT=true (init container), otherwise
# loops forever (sidecar).

set -eu

SQLITE_DATA_DIRECTORY="${SQLITE_DATA_DIRECTORY:-/data/sqlite}"
SQLITE_KEEP_LAST_N="${SQLITE_KEEP_LAST_N:-0}"
SYNC_INTERVAL_SECONDS="${SYNC_INTERVAL_SECONDS:-60}"
SYNC_ONESHOT="${SYNC_ONESHOT:-false}"
S3_PREFIX="s3://${SQLITE_S3_BUCKET:?Set SQLITE_S3_BUCKET}/${NETWORK:?Set NETWORK}"

log() {
  echo "[s3-sync-pull] $*"
}

# Lifecycle ids that have a body in S3, oldest first.
remote_lifecycle_ids() {
  aws s3 ls "${S3_PREFIX}/" \
    | awk '{ print $4 }' \
    | sed -n 's/^\([0-9][0-9]*\)\.sqlite$/\1/p' \
    | sort -n
}

retained_lifecycle_ids() {
  if [ "$SQLITE_KEEP_LAST_N" -gt 0 ]; then
    remote_lifecycle_ids | tail -n "$SQLITE_KEEP_LAST_N"
  else
    remote_lifecycle_ids
  fi
}

# Drops local bodies outside the retention window. Markers are left untouched.
# Removing a file the API already has open is safe: the open handle keeps
# working, and only a fresh lookup for that lifecycle will report it missing.
prune_bodies() {
  retained=$1
  [ "$SQLITE_KEEP_LAST_N" -gt 0 ] || return 0

  for path in "$SQLITE_DATA_DIRECTORY"/*.sqlite; do
    [ -e "$path" ] || continue
    id=$(basename "$path" .sqlite)
    if ! echo "$retained" | grep -qx "$id"; then
      log "pruning lifecycle ${id} (outside keep-last-${SQLITE_KEEP_LAST_N})"
      rm -f "$path" "$path-journal" "$path-wal" "$path-shm"
    fi
  done
}

sync_once() {
  mkdir -p "$SQLITE_DATA_DIRECTORY"

  # Markers first and in full - they are what marks a body complete.
  aws s3 sync "${S3_PREFIX}/" "${SQLITE_DATA_DIRECTORY}/" \
    --exclude '*' \
    --include '*.sqlite.done' \
    --include '*.sqlite.proven' \
    --only-show-errors

  retained=$(retained_lifecycle_ids)

  for id in $retained; do
    if [ ! -f "${SQLITE_DATA_DIRECTORY}/${id}.sqlite" ]; then
      log "fetching lifecycle ${id}"
      aws s3 cp "${S3_PREFIX}/${id}.sqlite" \
        "${SQLITE_DATA_DIRECTORY}/${id}.sqlite" --only-show-errors
    fi
  done

  prune_bodies "$retained"
}

main() {
  log "source=${S3_PREFIX} dir=${SQLITE_DATA_DIRECTORY} keepLastN=${SQLITE_KEEP_LAST_N}"

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

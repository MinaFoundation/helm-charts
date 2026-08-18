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

# Lifecycle ids whose body is *complete* in S3, oldest first.
#
# Keyed on the .done marker rather than on the body, because s3-sync-push
# uploads the body first and the marker only once it is whole. Listing bodies
# instead means fetching a database that is still being written: the local copy
# is then a truncated prefix of a valid SQLite file, which opens cleanly and
# simply contains fewer accounts. Proving it produces a root that fails
# prove-exhaust's assertEquals, forever, since nothing ever re-reads it.
remote_lifecycle_ids() {
  aws s3 ls "${S3_PREFIX}/" \
    | awk '{ print $4 }' \
    | sed -n 's/^\([0-9][0-9]*\)\.sqlite\.done$/\1/p' \
    | sort -n
}

# Size of a remote body, or empty if it cannot be read.
remote_body_size() {
  aws s3 ls "${S3_PREFIX}/$1.sqlite" 2>/dev/null | awk '{ print $3 }' | tail -n1
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
    local_path="${SQLITE_DATA_DIRECTORY}/${id}.sqlite"
    remote_size=$(remote_body_size "$id")

    # Compare sizes rather than testing existence alone. A body already pulled
    # while it was still being written stays wrong forever otherwise - there is
    # no later event that would refetch it, and the lifecycle retries and fails
    # on every cycle. Bodies are immutable once marked done, so a size that
    # differs can only mean the local copy is stale.
    if [ -f "$local_path" ] && [ -n "$remote_size" ]; then
      local_size=$(wc -c < "$local_path" | tr -d ' ')
      if [ "$local_size" = "$remote_size" ]; then
        continue
      fi
      log "refetching lifecycle ${id}: local ${local_size} bytes, remote ${remote_size}"
      rm -f "$local_path" "$local_path-wal" "$local_path-shm" "$local_path-journal"
    elif [ -f "$local_path" ]; then
      continue
    else
      log "fetching lifecycle ${id}"
    fi

    aws s3 cp "${S3_PREFIX}/${id}.sqlite" "$local_path" --only-show-errors
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

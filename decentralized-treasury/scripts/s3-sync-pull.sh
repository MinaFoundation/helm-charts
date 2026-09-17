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
# Every id gets its own real body, including the synthetic siblings an
# accelerated-testing release fans out (see lifecycleFanout in values.yaml).
# Bodies cannot be shared between ids: their rows are namespaced with the
# lifecycle id that produced them, so a borrowed body reads as an empty ledger.
# <id>.sqlite.alias objects and local symlinks are leftovers from an earlier
# scheme that did share them, and are cleaned up here.
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

# Size of a remote body, or empty if there is none.
#
# Matched on the exact key. `aws s3 ls` takes a prefix, so an id's own
# .sqlite.done, .sqlite.proven and .sqlite.alias objects are listed here too:
# reading any line's size reported a 173-byte marker as the body size, which
# made the "marker but no body" check below pass and sent the sync after a
# body that does not exist. One such id then aborted the whole cycle under
# `set -eu`, and the ids after it were never fetched.
remote_body_size() {
  aws s3 ls "${S3_PREFIX}/$1.sqlite" 2>/dev/null \
    | awk -v name="$1.sqlite" '$4 == name { print $3 }' \
    | tail -n1
}

# The id $1's body is aliased to, or empty if $1 has a real body of its own.
alias_target() {
  aws s3 cp "${S3_PREFIX}/$1.sqlite.alias" - 2>/dev/null
}

# Ids that have a body as well as a marker, so a window of N is N usable
# lifecycles. An id can carry a .done marker and no body at all - the retired
# alias scheme wrote a marker beside a pointer object - and ids like that would
# otherwise fill the whole window and leave the consumer with nothing: the
# observed case was keepLastN=2 retaining two such ids and never fetching the
# lifecycle that was actually in use.
lifecycle_ids_with_body() {
  for id in $(remote_lifecycle_ids); do
    if [ -n "$(remote_body_size "$id")" ]; then
      echo "$id"
    fi
  done
}

retained_lifecycle_ids() {
  if [ "$SQLITE_KEEP_LAST_N" -gt 0 ]; then
    lifecycle_ids_with_body | tail -n "$SQLITE_KEEP_LAST_N"
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
    echo "$retained" | grep -qx "$id" && continue
    log "pruning lifecycle ${id} (outside keep-last-${SQLITE_KEEP_LAST_N})"
    rm -f "$path" "$path-journal" "$path-wal" "$path-shm"
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

    # A body has to be this lifecycle's own file. Earlier revisions of
    # lifecycle-fanout-sync.sh published an <id>.sqlite.alias object naming
    # another lifecycle, and this script resolved it into a local symlink onto
    # that lifecycle's body. That is silently wrong: every row inside a body is
    # namespaced with the lifecycle id that produced it
    # ("staking-ledger-42-accounts:7"), so a consumer reading a borrowed body
    # finds none of its own keys and serves an empty ledger, and proposals in
    # that lifecycle fail the staking ledger root check. The fanout now
    # publishes a relabelled body per sibling instead; clear anything left over
    # from the alias scheme so the real body below replaces it.
    if [ -L "$local_path" ]; then
      log "lifecycle ${id} is a symlink onto $(readlink "$local_path") - dropping it, a borrowed body serves an empty ledger"
      rm -f "$local_path"
    fi
    if [ -n "$(alias_target "$id")" ]; then
      log "lifecycle ${id} still has a .sqlite.alias object in ${S3_PREFIX} - ignoring it, this lifecycle needs its own relabelled body"
    fi

    remote_size=$(remote_body_size "$id")

    # A .sqlite.done marker is supposed to guarantee a real body exists -
    # s3-sync-push only publishes a marker once the body is whole, and
    # lifecycle-fanout-sync publishes a sibling's marker only after its
    # relabelled body. Both missing means the producer-side invariant broke
    # (observed: stale/seed markers, and the marker an older fanout wrote next
    # to an alias object rather than a body). Log and skip this id rather than
    # run the unconditional `aws s3 cp` below, which would 404 under `set -eu`
    # and take down the whole sync - one broken id should not block every other
    # id in the window from syncing.
    if [ ! -f "$local_path" ] && [ -z "$remote_size" ]; then
      log "lifecycle ${id} has a .sqlite.done marker but no body in ${S3_PREFIX} - skipping"
      continue
    fi

    # Refetch only a body that is SMALLER than the remote one. A copy pulled
    # while it was still being written stays wrong forever otherwise: nothing
    # would ever refetch it, and the lifecycle fails on every cycle.
    #
    # Strictly smaller, not merely different, because these databases are not
    # read-only here - proving-scheduler writes its base proofs back into the
    # lifecycle body, so a healthy local copy grows past the remote one (~30 MB
    # local against ~27 MB in S3). Treating any difference as staleness would
    # redownload the file mid-digest and discard exactly those base proofs,
    # leaving merge with "No base proofs found".
    if [ -f "$local_path" ] && [ -n "$remote_size" ]; then
      local_size=$(wc -c < "$local_path" | tr -d ' ')
      if [ "$local_size" -ge "$remote_size" ]; then
        continue
      fi
      log "refetching lifecycle ${id}: local ${local_size} bytes is short of remote ${remote_size}"
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
    # Retried in-process rather than left to Kubernetes' container-level
    # restart backoff (10s/20s/40s/.../300s): the observed failures here are
    # transient (e.g. a freshly scheduled node's IRSA token or DNS not fully
    # settled yet), not configuration errors, and clear within a handful of
    # seconds - it should not cost the pod an Init:Error/CrashLoopBackOff
    # cycle, or the minutes of growing backoff that follow, to ride one out.
    # `sync_once` runs in a subshell so `set -eu` only ends that attempt, not
    # this script, whatever fails inside it.
    attempt=1
    max_attempts="${SYNC_ONESHOT_MAX_ATTEMPTS:-6}"
    retry_delay_seconds="${SYNC_ONESHOT_RETRY_DELAY_SECONDS:-5}"
    while true; do
      if ( sync_once ); then
        log "initial sync complete"
        return 0
      fi
      if [ "$attempt" -ge "$max_attempts" ]; then
        log "initial sync failed after ${attempt} attempts, giving up" >&2
        return 1
      fi
      log "initial sync attempt ${attempt}/${max_attempts} failed, retrying in ${retry_delay_seconds}s" >&2
      attempt=$(( attempt + 1 ))
      sleep "$retry_delay_seconds"
    done
  fi

  while true; do
    sync_once || log "sync cycle failed, retrying in ${SYNC_INTERVAL_SECONDS}s"
    sleep "$SYNC_INTERVAL_SECONDS"
  done
}

main

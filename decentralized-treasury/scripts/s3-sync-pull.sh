#!/bin/sh
# Hydrates the local SQLite lifecycle cache from S3 for read-only consumers.
#
# The lifecycle databases are produced by voting-ledger-scheduler and are
# immutable once their .done marker exists, so consumers only ever pull. The
# producer runs this too, with SQLITE_PULL_BODIES=false: it wants the markers
# and none of the bodies. Three rules come straight from how the application
# uses these files:
#
#   * Markers (.sqlite.done / .sqlite.proven) are never pruned. Both schedulers
#     decide what work remains purely from marker presence, and each marker is
#     a handful of bytes.
#   * Only .sqlite bodies are subject to SQLITE_KEEP_LAST_N, which retains the
#     N highest lifecycle ids. Set it to 0 to keep every body.
#
# Every id this pod serves ends up with its own real body. Bodies cannot be
# shared between ids - their rows are namespaced with the lifecycle id that
# produced them - so a grouped release materialises a sibling's body locally by
# relabelling its group's canonical, rather than borrowing the file. See the
# GROUPED LIFECYCLES block below. <id>.sqlite.alias objects and local symlinks
# are leftovers from an earlier scheme that did borrow them, and are cleaned up
# here.
#
# Runs one pass and exits when SYNC_ONESHOT=true (init container), otherwise
# loops forever (sidecar).

set -eu

SQLITE_DATA_DIRECTORY="${SQLITE_DATA_DIRECTORY:-/data/sqlite}"
SQLITE_KEEP_LAST_N="${SQLITE_KEEP_LAST_N:-0}"
# Whether to fetch bodies at all, or only the markers.
#
# A producer needs the markers - they are how it knows which lifecycles are
# already built - but not the bodies: it writes the one it is building itself,
# resumes from its own checkpoint under the .checkpoints/ prefix, and decides
# what is already produced by listing S3, never the local directory. Fetching
# every other lifecycle's body costs it minutes of startup and tens of GB of
# disk for data it never opens: measured at 37.6GB and 5.3 minutes on a
# voting-ledger-scheduler that read none of it.
SQLITE_PULL_BODIES="${SQLITE_PULL_BODIES:-true}"
SYNC_INTERVAL_SECONDS="${SYNC_INTERVAL_SECONDS:-60}"
SYNC_ONESHOT="${SYNC_ONESHOT:-false}"
S3_PREFIX="s3://${SQLITE_S3_BUCKET:?Set SQLITE_S3_BUCKET}/${NETWORK:?Set NETWORK}"

# GROUPED LIFECYCLES (see lifecycleFanout in values.yaml). Only the canonical
# id of each group - id % groupSize == 0 - is ever built and published. The
# other ids in the group share that one staking ledger, and this pod
# materialises the ones it actually needs from the canonical's body, locally.
#
# It has to be a relabelled copy, not a link: the rows inside a body are
# namespaced with the lifecycle id that produced them
# ("staking-ledger-42-accounts:7"), so a reader opening the canonical's bytes
# under a sibling's name asks for keys that are not in the file and serves an
# empty ledger. That is what the retired <id>.sqlite.alias scheme did, and it
# failed silently.
#
# Nothing materialised here is ever published: siblings get no body, no marker
# and no alias in the bucket, and s3-sync-push.sh excludes them by their
# <id>.sqlite.sibling pointer. A sibling body in the bucket would hand every
# other consumer data for an id the producers never built.
LIFECYCLE_ANCHOR_GROUP_SIZE="${LIFECYCLE_ANCHOR_GROUP_SIZE:-1}"
MATERIALISE_SIBLINGS="${MATERIALISE_SIBLINGS:-false}"
# How far around the lifecycle the chain is in to materialise. Each sibling
# costs one copy of a body on this pod's disk, so this is deliberately small:
# the default covers the current lifecycle and the next one, which is what a
# proposal being created and a proposal about to be created need.
SIBLING_WINDOW_BEHIND="${SIBLING_WINDOW_BEHIND:-0}"
SIBLING_WINDOW_AHEAD="${SIBLING_WINDOW_AHEAD:-1}"
LIFECYCLE_PERIOD_DURATION="${LIFECYCLE_PERIOD_DURATION:-0}"
PERIODS_PER_LIFECYCLE="${PERIODS_PER_LIFECYCLE:-4}"
TREASURY_DEPLOYED_AT_SLOT="${TREASURY_DEPLOYED_AT_SLOT:-0}"
MINA_NODE_URL="${MINA_NODE_URL:-}"
RELABEL_SCRIPT="${RELABEL_SCRIPT:-/scripts/relabel-lifecycle-sqlite.py}"
# Marks a body as a local relabelled copy rather than a published one.
# s3-sync-push.sh reads these to build its exclude list.
SIBLING_POINTER_SUFFIX=".sibling"

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
  # A grouped consumer needs exactly the canonicals its window relabels from.
  # Keep-last-N is the wrong rule there: it follows the highest id, and the
  # newest canonical can be built a whole group ahead of the chain, so the
  # window would fill with a body nothing needs yet while evicting the one the
  # current lifecycle is relabelled from. Falls through to keep-last-N when the
  # chain cannot be reached, so an unreachable daemon never prunes the cache.
  if [ "$MATERIALISE_SIBLINGS" = "true" ] && [ "$LIFECYCLE_ANCHOR_GROUP_SIZE" -gt 1 ]; then
    anchors=$(window_anchors)
    if [ -n "$anchors" ]; then
      echo "$anchors"
      return 0
    fi
  fi

  if [ "$SQLITE_KEEP_LAST_N" -gt 0 ]; then
    lifecycle_ids_with_body | tail -n "$SQLITE_KEEP_LAST_N"
  else
    remote_lifecycle_ids
  fi
}

# Drops local bodies outside the retention window. Markers are left untouched.
# Removing a file the API already has open is safe: the open handle keeps
# working, and only a fresh lookup for that lifecycle will report it missing.
#
# $2 is the set of materialised sibling ids currently in the window. They have
# no marker and no remote body, so the retention window above knows nothing
# about them; without this every cycle would delete the sibling the previous
# cycle just spent minutes relabelling.
prune_bodies() {
  retained=$1
  siblings=$2

  for path in "$SQLITE_DATA_DIRECTORY"/*.sqlite; do
    [ -e "$path" ] || continue
    id=$(basename "$path" .sqlite)
    echo "$siblings" | grep -qx "$id" && continue
    if [ -f "${path}${SIBLING_POINTER_SUFFIX}" ]; then
      log "dropping materialised sibling ${id} (outside the sibling window)"
      rm -f "$path" "$path-journal" "$path-wal" "$path-shm" \
        "${path}${SIBLING_POINTER_SUFFIX}"
      continue
    fi
    [ "$SQLITE_KEEP_LAST_N" -gt 0 ] || continue
    echo "$retained" | grep -qx "$id" && continue
    log "pruning lifecycle ${id} (outside keep-last-${SQLITE_KEEP_LAST_N})"
    rm -f "$path" "$path-journal" "$path-wal" "$path-shm"
  done
}

# The canonical id of $1's group. With groupSize 1 - every normal release -
# this is $1 itself, so nothing below changes anything.
anchor_of() {
  echo $(( $1 - ($1 % LIFECYCLE_ANCHOR_GROUP_SIZE) ))
}

# The lifecycle the chain is in, or empty if it cannot be worked out.
#
# Deliberately never fatal. Hydrating the cache matters more than
# materialising siblings, so an unreachable daemon costs one cycle of
# materialisation rather than the whole sync.
chain_lifecycle_id() {
  [ -n "$MINA_NODE_URL" ] || { log "MATERIALISE_SIBLINGS is set but MINA_NODE_URL is empty - skipping"; return 0; }
  [ "$LIFECYCLE_PERIOD_DURATION" -gt 0 ] || { log "MATERIALISE_SIBLINGS is set but LIFECYCLE_PERIOD_DURATION is 0 - skipping"; return 0; }

  query='{"query":"{ bestChain(maxLength:1) { protocolState { consensusState { slotSinceGenesis } } } }"}'
  slot=$(curl -sS --max-time 30 -H 'Content-Type: application/json' \
    -d "$query" "$MINA_NODE_URL" 2>/dev/null \
    | sed -n 's/.*"slotSinceGenesis":"\{0,1\}\([0-9][0-9]*\)"\{0,1\}.*/\1/p') || true
  case "$slot" in
    ''|*[!0-9]*) log "could not read slotSinceGenesis from ${MINA_NODE_URL} - skipping sibling materialisation this cycle"; return 0 ;;
  esac
  [ "$slot" -ge "$TREASURY_DEPLOYED_AT_SLOT" ] || return 0
  echo $(( (slot - TREASURY_DEPLOYED_AT_SLOT) / (LIFECYCLE_PERIOD_DURATION * PERIODS_PER_LIFECYCLE) ))
}

# The lifecycle ids this pod should be able to serve: the window around the one
# the chain is in. Empty when grouping is off or the chain cannot be reached.
#
# SIBLING_WINDOW_AHEAD must stay >= 1. A body that only appears once its
# lifecycle has already opened is worse than slow: the processor polls every
# couple of seconds, so it burns its five attempts on the missing ledger within
# seconds and parks a `blocked` failure row, which halts the queue until
# someone resets it by hand.
lifecycle_window() {
  [ "$MATERIALISE_SIBLINGS" = "true" ] || return 0
  [ "$LIFECYCLE_ANCHOR_GROUP_SIZE" -gt 1 ] || return 0

  tip=$(chain_lifecycle_id)
  [ -n "$tip" ] || return 0

  from=$(( tip - SIBLING_WINDOW_BEHIND ))
  [ "$from" -lt 0 ] && from=0
  to=$(( tip + SIBLING_WINDOW_AHEAD ))

  id=$from
  while [ "$id" -le "$to" ]; do
    echo "$id"
    id=$(( id + 1 ))
  done
}

# The ids in the window that are not their own group's canonical, i.e. the ones
# that have to be relabelled locally.
sibling_window() {
  for id in $(lifecycle_window); do
    [ "$id" -ne "$(anchor_of "$id")" ] && echo "$id"
  done
}

# The canonicals the window relabels from, deduplicated.
window_anchors() {
  for id in $(lifecycle_window); do
    anchor_of "$id"
  done | sort -n -u
}

# Relabels the group's canonical body into $1's own, in place on this pod.
#
# Written to a .part file and renamed, with the pointer in place before the
# rename, so an interrupted run never leaves a body that prune_bodies would
# mistake for a real one.
materialise_sibling() {
  id=$1
  anchor=$(anchor_of "$id")
  target="${SQLITE_DATA_DIRECTORY}/${id}.sqlite"
  source_body="${SQLITE_DATA_DIRECTORY}/${anchor}.sqlite"

  [ -f "$target" ] && return 0
  if [ ! -f "$source_body" ]; then
    log "lifecycle ${id} needs canonical ${anchor}, which is not cached yet - retrying next cycle"
    return 0
  fi

  log "materialising lifecycle ${id} from canonical ${anchor} (relabelling ~$(wc -c < "$source_body") bytes, takes minutes)"
  rm -f "${target}.part"
  if ! python3 "$RELABEL_SCRIPT" "$source_body" "${target}.part" "$anchor" "$id"; then
    log "relabel failed for lifecycle ${id} - leaving it absent rather than serving a wrong ledger"
    rm -f "${target}.part"
    return 0
  fi
  printf '%s' "$anchor" > "${target}${SIBLING_POINTER_SUFFIX}"
  mv "${target}.part" "$target"
  log "lifecycle ${id} is now served from its own relabelled body"
}

sync_once() {
  mkdir -p "$SQLITE_DATA_DIRECTORY"

  # Markers first and in full - they are what marks a body complete.
  aws s3 sync "${S3_PREFIX}/" "${SQLITE_DATA_DIRECTORY}/" \
    --exclude '*' \
    --include '*.sqlite.done' \
    --include '*.sqlite.proven' \
    --only-show-errors

  if [ "$SQLITE_PULL_BODIES" != "true" ]; then
    log "markers only: this workload produces bodies rather than reading them"
    return 0
  fi

  retained=$(retained_lifecycle_ids)

  siblings=$(sibling_window)

  for id in $retained; do
    local_path="${SQLITE_DATA_DIRECTORY}/${id}.sqlite"

    # A body has to be this lifecycle's own file. A retired fan-out published
    # an <id>.sqlite.alias object naming another lifecycle, and this script
    # resolved it into a local symlink onto that lifecycle's body. That is
    # silently wrong: every row inside a body is namespaced with the lifecycle
    # id that produced it ("staking-ledger-42-accounts:7"), so a consumer
    # reading a borrowed body finds none of its own keys and serves an empty
    # ledger, and proposals in that lifecycle fail the staking ledger root
    # check. Siblings are relabelled locally now (see GROUPED LIFECYCLES
    # above); clear anything left over from the alias scheme.
    if [ -L "$local_path" ]; then
      log "lifecycle ${id} is a symlink onto $(readlink "$local_path") - dropping it, a borrowed body serves an empty ledger"
      rm -f "$local_path"
    fi
    if [ -n "$(alias_target "$id")" ]; then
      log "lifecycle ${id} still has a .sqlite.alias object in ${S3_PREFIX} - ignoring it, this lifecycle needs its own relabelled body"
    fi

    remote_size=$(remote_body_size "$id")

    # A .sqlite.done marker is supposed to guarantee a real body exists -
    # s3-sync-push only publishes a marker once the body is whole. Both missing
    # means the producer-side invariant broke (observed: stale/seed markers, and
    # the markers a retired fan-out wrote next to alias objects rather than
    # bodies). Log and skip this id rather than
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

  for id in $siblings; do
    materialise_sibling "$id"
  done

  prune_bodies "$retained" "$siblings"
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

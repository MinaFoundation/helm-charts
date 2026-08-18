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
# STAKING_LEDGERS_KEEP_LAST_N is how far back from the newest lifecycle to
# look, counted in lifecycles. Anchoring to the tip is what stops the sync and
# the scheduler from walking backwards through the whole backlog together; see
# wanted_archives. 1 tracks the tip only, 0 takes every unproduced lifecycle
# and so opts into backfilling all of history.

set -eu

STAKING_LEDGERS_DIRECTORY="${STAKING_LEDGERS_DIRECTORY:-/staking-ledgers}"
STAKING_LEDGERS_KEEP_LAST_N="${STAKING_LEDGERS_KEEP_LAST_N:-0}"
# Comma-separated lifecycle ids. Overrides the window when set.
LIFECYCLE_IDS="${LIFECYCLE_IDS:-}"
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

# The highest lifecycle id the bucket has a staking ledger for, produced or
# not. This is the tip the window below is anchored to.
newest_lifecycle_id() {
  newest=""
  for name in $(remote_archives); do
    lifecycle_id=$(lifecycle_id_for_epoch "$(epoch_of "$name")") || continue
    newest=$lifecycle_id
  done
  printf '%s' "$newest"
}

# Archives worth having locally: the unproduced lifecycles within
# STAKING_LEDGERS_KEEP_LAST_N of the tip.
#
# The window is anchored to the newest lifecycle rather than simply taking the
# newest unproduced ones, and that is the whole point of it. The scheduler
# processes the newest *unproduced* lifecycle, so feeding it any unproduced
# archive from anywhere in history makes the pair walk steadily backwards
# through the entire backlog. That is unusable on a network where one ledger
# takes hours. Anchored to the tip, the sync goes quiet as soon as the recent
# lifecycles are built, and only wakes when a genuinely new epoch lands.
#
# Backfilling old lifecycles is therefore opt-in: widen the window, or set it
# to 0 for every unproduced lifecycle.
wanted_archives() {
  produced=$1

  # An explicit list replaces the window entirely: name the lifecycles and only
  # those are fetched, whatever the tip is. Backfilling a specific gap is the
  # point, so it is the one case where reaching far back is deliberate.
  #
  # Still filtered by `produced`, which is what makes naming a lifecycle
  # idempotent - a list can be left in place across deploys and the ones
  # already built are simply skipped rather than rebuilt.
  if [ -n "$LIFECYCLE_IDS" ]; then
    wanted=""
    for name in $(remote_archives); do
      lifecycle_id=$(lifecycle_id_for_epoch "$(epoch_of "$name")") || continue
      echo "$LIFECYCLE_IDS" | tr ',' '\n' | grep -qx "$lifecycle_id" || continue
      if echo "$produced" | grep -qx "$lifecycle_id"; then
        continue
      fi
      wanted="${wanted}${name}
"
    done
    printf '%s' "$wanted" | grep -v '^$' || true
    return 0
  fi

  tip=$(newest_lifecycle_id)
  [ -n "$tip" ] || return 0

  floor=0
  if [ "$STAKING_LEDGERS_KEEP_LAST_N" -gt 0 ]; then
    floor=$(( tip - STAKING_LEDGERS_KEEP_LAST_N + 1 ))
    [ "$floor" -lt 0 ] && floor=0
  fi

  wanted=""
  for name in $(remote_archives); do
    lifecycle_id=$(lifecycle_id_for_epoch "$(epoch_of "$name")") || continue
    [ "$lifecycle_id" -ge "$floor" ] || continue
    if echo "$produced" | grep -qx "$lifecycle_id"; then
      continue
    fi
    wanted="${wanted}${name}
"
  done

  printf '%s' "$wanted" | grep -v '^$' || true
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
    if [ -n "$LIFECYCLE_IDS" ]; then
      log "nothing to fetch: every lifecycle in [${LIFECYCLE_IDS}] already has a voting ledger in ${SQLITE_S3_PREFIX}"
    else
      log "nothing to fetch: every lifecycle within keep-last-${STAKING_LEDGERS_KEEP_LAST_N} of the newest already has a voting ledger in ${SQLITE_S3_PREFIX}"
    fi
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
  if [ -n "$LIFECYCLE_IDS" ]; then
    log "source=${S3_PREFIX} dir=${STAKING_LEDGERS_DIRECTORY} lifecycleIds=[${LIFECYCLE_IDS}] deployedEpoch=${DEPLOYED_EPOCH} periodsPerLifecycle=${PERIODS_PER_LIFECYCLE}"
  else
    log "source=${S3_PREFIX} dir=${STAKING_LEDGERS_DIRECTORY} keepLastN=${STAKING_LEDGERS_KEEP_LAST_N} deployedEpoch=${DEPLOYED_EPOCH} periodsPerLifecycle=${PERIODS_PER_LIFECYCLE}"
  fi

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

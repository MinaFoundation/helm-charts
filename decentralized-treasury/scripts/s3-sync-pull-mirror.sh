#!/bin/sh
# Hydrates a local directory from an S3 prefix by plain mirroring - no marker
# files, no partial-write handling, no retention window.
#
# Unlike s3-sync-pull.sh (which the sqlite cache needs, because a .sqlite body
# can be caught mid-write and a marker says when it's actually whole), this is
# for directories where every object is already complete by the time it lands
# in S3: s3-sync-push.sh only uploads a payload pattern in one pass, so a
# listed object is always the finished file, never a partial one.
#
# Read-only consumer: never deletes anything, locally or in S3, so a pull that
# lags behind an eventually-consistent listing just means a later cycle picks
# up what this one missed.
#
# Runs one pass and exits when SYNC_ONESHOT=true (init container), otherwise
# loops forever (sidecar).

set -eu

SOURCE_PREFIX="${SOURCE_PREFIX:?Set SOURCE_PREFIX}"
TARGET_DIRECTORY="${TARGET_DIRECTORY:?Set TARGET_DIRECTORY}"
SYNC_INTERVAL_SECONDS="${SYNC_INTERVAL_SECONDS:-60}"
SYNC_ONESHOT="${SYNC_ONESHOT:-false}"

log() {
  echo "[s3-sync-pull-mirror] $*"
}

sync_once() {
  mkdir -p "$TARGET_DIRECTORY"
  aws s3 sync "${SOURCE_PREFIX}/" "${TARGET_DIRECTORY}/" --only-show-errors
}

main() {
  log "source=${SOURCE_PREFIX} dir=${TARGET_DIRECTORY}"

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

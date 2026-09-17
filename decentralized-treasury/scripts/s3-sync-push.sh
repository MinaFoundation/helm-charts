#!/bin/sh
# Publishes locally produced artifacts to S3 for the two scheduler workloads.
#
# Upload order is the point of this script. Consumers treat a marker file as
# proof that its payload is complete, so payloads are uploaded first and markers
# only afterwards. `aws s3 sync` gives no ordering guarantee within one call,
# hence the two explicit phases.
#
#   voting-ledger-scheduler  payload=*.sqlite         marker=*.sqlite.done
#   proving-scheduler        payload=(proofs)         marker=*.sqlite.proven
#
# Either phase may be left empty. Nothing here deletes remote objects: local
# retention pruning must never propagate to S3, which is the durable copy.

set -eu

SOURCE_DIRECTORY="${SOURCE_DIRECTORY:?Set SOURCE_DIRECTORY}"
S3_TARGET_PREFIX="${S3_TARGET_PREFIX:?Set S3_TARGET_PREFIX}"
PUSH_PAYLOAD_INCLUDES="${PUSH_PAYLOAD_INCLUDES:-}"
PUSH_MARKER_INCLUDES="${PUSH_MARKER_INCLUDES:-}"
SYNC_INTERVAL_SECONDS="${SYNC_INTERVAL_SECONDS:-60}"

log() {
  echo "[s3-sync-push] $*"
}

# Builds the --include arguments for one phase and runs the upload. Skips
# entirely when that phase has no patterns configured.
push_phase() {
  phase=$1
  includes=$2

  [ -n "$includes" ] || return 0

  # --no-follow-symlinks: a lifecycle body left as a local symlink onto
  # another id's body by the retired alias scheme (see lifecycleFanout in
  # values.yaml) must never be re-uploaded under its own key - the rows inside
  # it are namespaced with the other lifecycle's id. s3-sync-pull.sh deletes
  # such links on sight now; this stays as a second line of defence, and is a
  # no-op for every release that never had one.
  set -- "$SOURCE_DIRECTORY/" "$S3_TARGET_PREFIX/" --exclude '*' --no-follow-symlinks --only-show-errors
  # set -f while splitting: these patterns are for `aws s3 sync` to interpret,
  # and an unquoted expansion would let the shell resolve "*.sqlite" against
  # the working directory first, quietly turning a pattern into whatever
  # filenames happen to sit there.
  set -f
  for pattern in $includes; do
    set +f
    set -- "$@" --include "$pattern"
    set -f
  done
  set +f

  # A materialised sibling is a relabelled copy of another lifecycle's body,
  # made locally by s3-sync-pull.sh for this pod to read (see GROUPED
  # LIFECYCLES there). Publishing one would hand every other consumer a body
  # for an id the producers never built, and its marker would promise work that
  # was never done - so each is excluded by name, after the includes, along
  # with the pointer files themselves.
  set -- "$@" --exclude '*.sqlite.sibling'
  for pointer in "$SOURCE_DIRECTORY"/*.sqlite.sibling; do
    [ -e "$pointer" ] || continue
    body=$(basename "$pointer" .sibling)
    log "not publishing ${body}: materialised locally from canonical $(cat "$pointer")"
    set -- "$@" --exclude "$body" --exclude "${body}.done" --exclude "${body}.proven"
  done

  log "pushing ${phase} (${includes})"
  aws s3 sync "$@"
}

sync_once() {
  [ -d "$SOURCE_DIRECTORY" ] || return 0

  push_phase payloads "$PUSH_PAYLOAD_INCLUDES"
  push_phase markers "$PUSH_MARKER_INCLUDES"
}

main() {
  log "source=${SOURCE_DIRECTORY} target=${S3_TARGET_PREFIX}"

  while true; do
    sync_once || log "push cycle failed, retrying in ${SYNC_INTERVAL_SECONDS}s"
    sleep "$SYNC_INTERVAL_SECONDS"
  done
}

main

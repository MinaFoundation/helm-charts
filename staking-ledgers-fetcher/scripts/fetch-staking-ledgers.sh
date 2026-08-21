#!/bin/bash
# Exports Mina staking ledgers from an in-cluster daemon into a local directory,
# which a sibling nginx container serves in-namespace. Nothing leaves the
# cluster and no object store is involved.
#
# WHY OBJECTS ARE NAMED BY LEDGER HASH. Mina resets the epoch number to 0 at
# every hardfork, so an epoch identifies a ledger only within one era - mainnet
# currently holds an epoch 54 from 2023 and a different epoch 54 from 2026 for
# exactly that reason. The ledger hash does not collide, and it is the value the
# treasury circuits enforce: a proposal snapshots stakingEpochData.ledger.hash
# on-chain, and the proof asserts the hydrated ledger roots to it. So the hash
# is the identity here, and the archive member is named by it too. The epoch is
# kept in the object name only so a human can browse by eye - the consumer
# matches on the hash.
#
# Both the current and next epoch ledger are exported. next(N) is byte-identical
# to staking(N+1), so publishing it early gives the treasury up to a full epoch
# of head start on a build whose tracing step alone runs for hours.
set -euo pipefail

LEDGERS_DIRECTORY="${APP_LEDGERS_DIRECTORY:-/data}"
MINA_NODE_LABEL="${APP_MINA_NODE_LABEL:?Set APP_MINA_NODE_LABEL}"
MINA_CONTAINER="${APP_MINA_CONTAINER:-mina}"
MINA_NAMESPACE="${APP_MINA_NAMESPACE:-}"
EXPORT_NEXT_EPOCH="${APP_EXPORT_NEXT_EPOCH:-true}"
KEEP_LAST_N="${APP_KEEP_LAST_N:-4}"
POLL_INTERVAL_SECONDS="${APP_POLL_INTERVAL_SECONDS:-3600}"
ONESHOT="${APP_ONESHOT:-false}"

LEDGER_HASH_PATTERN='^j[1-9A-HJ-NP-Za-km-z]{40,60}$'

log()       { echo "[staking-ledgers-fetcher] $*"; }
log_warn()  { echo "[staking-ledgers-fetcher] WARN $*" >&2; }
log_error() { echo "[staking-ledgers-fetcher] ERROR $*" >&2; }
die()       { log_error "$*"; exit 1; }

kube() {
  if [ -n "$MINA_NAMESPACE" ]; then kubectl -n "$MINA_NAMESPACE" "$@"; else kubectl "$@"; fi
}

on_pod() { kube exec "$SYNCED_POD" -c "$MINA_CONTAINER" -- /bin/sh -c "$1"; }

# The daemon must report Synced, or `mina ledger export` yields a ledger for a
# chain we are not actually following - which would then fail verification
# downstream after hours of tracing rather than here in seconds.
find_synced_pod() {
  pods=$(kube get pods -l "$MINA_NODE_LABEL" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || true)
  [ -n "$pods" ] || { log_error "no pods match label '${MINA_NODE_LABEL}'"; return 1; }

  for pod in $pods; do
    status=$(kube exec "$pod" -c "$MINA_CONTAINER" -- /bin/sh -c \
      '/usr/local/bin/mina client status --json 2>/dev/null' 2>/dev/null || true)
    [ -n "$status" ] || continue
    sync=$(printf '%s' "$status" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("sync_status",""))' 2>/dev/null || true)
    if [ "$sync" = "Synced" ]; then
      SYNCED_POD=$pod
      DAEMON_STATUS=$status
      log "using synced node: ${pod}"
      return 0
    fi
    log_warn "skipping ${pod}: sync_status=${sync:-unknown}"
  done
  log_error "no synced node among: ${pods}"
  return 1
}

read_epochs() {
  CURRENT_EPOCH=$(printf '%s' "$DAEMON_STATUS" | python3 -c '
import json,sys
d = json.load(sys.stdin)["consensus_time_now"]
print(int(d["slot_number"]) // int(d["slots_per_epoch"]))
') || { log_error "could not derive the current epoch from daemon status"; return 1; }
  NEXT_EPOCH=$(( CURRENT_EPOCH + 1 ))
  log "currentEpoch=${CURRENT_EPOCH} nextEpoch=${NEXT_EPOCH}"
}

# Counts published archives via a glob rather than by parsing ls.
archive_count() {
  set -- "${LEDGERS_DIRECTORY}"/*.json.tar.gz
  if [ "$1" = "${LEDGERS_DIRECTORY}/*.json.tar.gz" ] && [ ! -e "$1" ]; then
    echo 0
  else
    echo $#
  fi
}

have_ledger_hash() {
  ls "${LEDGERS_DIRECTORY}"/*-"$1".json.tar.gz >/dev/null 2>&1
}

publish_ledger() {
  which_ledger=$1
  epoch=$2

  log "exporting ${which_ledger} (epoch ${epoch})"
  on_pod "/usr/local/bin/mina ledger export ${which_ledger} > /tmp/${which_ledger}.json" || return 1

  hash=$(on_pod "/usr/local/bin/mina ledger hash --ledger-file /tmp/${which_ledger}.json" \
    | tr -d '[:space:]' | grep -E "$LEDGER_HASH_PATTERN") \
    || { log_error "mina ledger hash returned no plausible hash for ${which_ledger}"; return 1; }
  log "  ledgerHash=${hash}"

  # The hash is the identity, so an archive already carrying it is by definition
  # the same ledger. Re-exporting 100+MB every cycle would be pure waste.
  if have_ledger_hash "$hash"; then
    log "  already present, skipping"
    on_pod "rm -f /tmp/${which_ledger}.json" || true
    return 0
  fi

  object="staking-${epoch}-${hash}.json.tar.gz"

  # Packed on the node so only the compressed archive crosses the kubectl cp
  # stream, and the member is named by the hash so the archive is
  # content-addressed all the way down.
  on_pod "mv /tmp/${which_ledger}.json /tmp/${hash}.json && tar -C /tmp -czf /tmp/${object} ${hash}.json && rm -f /tmp/${hash}.json" || return 1

  kube cp "${SYNCED_POD}:/tmp/${object}" "${LEDGERS_DIRECTORY}/.${object}.part" -c "$MINA_CONTAINER" || {
    on_pod "rm -f /tmp/${object}" || true
    rm -f "${LEDGERS_DIRECTORY}/.${object}.part"
    return 1
  }
  on_pod "rm -f /tmp/${object}" || true

  [ -s "${LEDGERS_DIRECTORY}/.${object}.part" ] || {
    log_error "copied archive ${object} is empty"
    rm -f "${LEDGERS_DIRECTORY}/.${object}.part"
    return 1
  }

  # Verified before it is published, since everything downstream trusts it.
  if ! python3 - "${LEDGERS_DIRECTORY}/.${object}.part" "$hash" <<'PY'
import json, sys, tarfile
archive, expected = sys.argv[1], sys.argv[2]
with tarfile.open(archive, "r:gz") as tar:
    members = [m for m in tar.getmembers() if m.isfile() and m.name.endswith(".json")]
    if len(members) != 1:
        sys.exit("expected exactly one .json member, found %d" % len(members))
    if members[0].name != "%s.json" % expected:
        sys.exit("member is %s, expected %s.json" % (members[0].name, expected))
    accounts = json.load(tar.extractfile(members[0]))
if not isinstance(accounts, list) or not accounts:
    sys.exit("ledger is not a non-empty JSON array")
if "pk" not in accounts[0]:
    sys.exit("ledger entries do not look like accounts")
print("  archive verified: %d accounts" % len(accounts))
PY
  then
    log_error "archive ${object} failed verification"
    rm -f "${LEDGERS_DIRECTORY}/.${object}.part"
    return 1
  fi

  # Renamed into place only once complete, so a consumer listing the directory
  # never sees a partial archive.
  mv "${LEDGERS_DIRECTORY}/.${object}.part" "${LEDGERS_DIRECTORY}/${object}"
  log "  published ${object}"
}

# Keeps the newest N archives by modification time. Deliberately generous: a
# lifecycle can need a ledger several epochs old, and re-exporting one the
# daemon no longer serves is impossible.
prune() {
  [ "$KEEP_LAST_N" -gt 0 ] || return 0
  [ "$(archive_count)" -gt "$KEEP_LAST_N" ] || return 0

  # shellcheck disable=SC2012  # names are generated here as
  # staking-<epoch>-<hash>.json.tar.gz, so they hold no whitespace or newlines;
  # ls -t is the clearest way to order by recency.
  ls -1t "${LEDGERS_DIRECTORY}"/*.json.tar.gz 2>/dev/null | tail -n +$(( KEEP_LAST_N + 1 )) | while read -r path; do
    log "pruning $(basename "$path") (keeping newest ${KEEP_LAST_N})"
    rm -f "$path"
  done
}

heartbeat() {
  cat > "${LEDGERS_DIRECTORY}/.fetch-status" <<EOF
{
  "lastSuccessEpochSeconds": $(date +%s),
  "lastSuccessAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "currentEpoch": ${CURRENT_EPOCH:-null},
  "archives": $(archive_count)
}
EOF
}

fetch_once() {
  mkdir -p "$LEDGERS_DIRECTORY"
  rm -f "${LEDGERS_DIRECTORY}"/.*.part 2>/dev/null || true

  find_synced_pod || return 1
  read_epochs || return 1

  publish_ledger staking-epoch-ledger "$CURRENT_EPOCH" || return 1

  if [ "$EXPORT_NEXT_EPOCH" = "true" ]; then
    # Not fatal: early in an epoch the daemon may not serve a next-epoch ledger
    # yet, and the current one is what is needed right now regardless.
    publish_ledger next-epoch-ledger "$NEXT_EPOCH" \
      || log_warn "could not export next-epoch-ledger; continuing"
  fi

  prune
  heartbeat
  log "cycle complete: $(archive_count) archive(s) available"
}

main() {
  for tool in kubectl python3 tar; do
    command -v "$tool" >/dev/null 2>&1 || die "required tool '${tool}' is not on PATH"
  done

  log "dir=${LEDGERS_DIRECTORY} nodeLabel=${MINA_NODE_LABEL} namespace=${MINA_NAMESPACE:-<release>} keepLastN=${KEEP_LAST_N}"

  if [ "$ONESHOT" = "true" ]; then
    fetch_once
    return 0
  fi

  while true; do
    fetch_once || log_warn "fetch cycle failed, retrying in ${POLL_INTERVAL_SECONDS}s"
    sleep "$POLL_INTERVAL_SECONDS"
  done
}

main "$@"

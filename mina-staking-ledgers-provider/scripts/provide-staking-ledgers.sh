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
# GraphQL port on the daemon pod. Queried on the pod's own IP rather than
# through a Service: the ledger hash has to come from the very node the export
# runs on, and a Service would balance across every pod matching its own
# selector - which is not the same selector used to pick the synced pod here.
# Reading the hash from one node and exporting from another silently compares
# two different chains' answers.
MINA_GRAPHQL_PORT="${APP_MINA_GRAPHQL_PORT:-3085}"
# Cheap probe endpoint, typically a Service. Used only to decide whether there
# is any work to do, before touching a pod at all: if the ledgers the chain
# advertises are already published, the cycle ends without a single exec. It is
# deliberately NOT trusted for the export itself - see chain_ledger_hashes.
MINA_NODE_URL="${APP_MINA_NODE_URL:-}"
EXPORT_NEXT_EPOCH="${APP_EXPORT_NEXT_EPOCH:-true}"
KEEP_LAST_N="${APP_KEEP_LAST_N:-4}"
POLL_INTERVAL_SECONDS="${APP_POLL_INTERVAL_SECONDS:-3600}"
ONESHOT="${APP_ONESHOT:-false}"

LEDGER_HASH_PATTERN='^j[1-9A-HJ-NP-Za-km-z]{40,60}$'

log()       { echo "[staking-ledgers-provider] $*"; }
log_warn()  { echo "[staking-ledgers-provider] WARN $*" >&2; }
log_error() { echo "[staking-ledgers-provider] ERROR $*" >&2; }
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
      SYNCED_POD_IP=$(kube get pod "$pod" -o jsonpath='{.status.podIP}' 2>/dev/null || true)
      log "using synced node: ${pod}${SYNCED_POD_IP:+ (${SYNCED_POD_IP})}"
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

# Ledger hashes the chain says are in force, without touching the ledger itself.
# Sets CHAIN_STAKING_HASH / CHAIN_NEXT_HASH, or returns 1 if unavailable.
# Reads the ledger hashes (and epoch) a given endpoint advertises.
#
# Called twice, deliberately, against different endpoints. First against
# MINA_NODE_URL - any node will do, because the answer is only used to decide
# whether work is needed. Then, once a pod has been chosen, against that pod's
# own IP: the hash used to name and verify an export must come from the daemon
# that produced it, or two different nodes' views get compared.
chain_ledger_hashes() {
  node_url=$1
  command -v curl >/dev/null 2>&1 || return 1

  response=$(curl -sS --max-time 30 -X POST -H 'Content-Type: application/json' \
    -d '{"query":"{ daemonStatus { syncStatus consensusConfiguration { slotsPerEpoch } } bestChain(maxLength:1){ protocolState{ consensusState{ epoch stakingEpochData{ ledger{ hash } } nextEpochData{ ledger{ hash } } } } } }"}' \
    "$node_url" 2>/dev/null) || return 1

  CHAIN_SYNC_STATUS=$(printf '%s' "$response" | python3 -c '
import json,sys
try:
    print(json.load(sys.stdin)["data"]["daemonStatus"]["syncStatus"])
except Exception:
    sys.exit(1)
') || return 1

  CHAIN_EPOCH=$(printf '%s' "$response" | python3 -c '
import json,sys
try:
    print(json.load(sys.stdin)["data"]["bestChain"][0]["protocolState"]["consensusState"]["epoch"])
except Exception:
    sys.exit(1)
') || return 1

  CHAIN_STAKING_HASH=$(printf '%s' "$response" | python3 -c '
import json,sys
try:
    c = json.load(sys.stdin)["data"]["bestChain"][0]["protocolState"]["consensusState"]
    print(c["stakingEpochData"]["ledger"]["hash"])
except Exception:
    sys.exit(1)
') || return 1
  CHAIN_NEXT_HASH=$(printf '%s' "$response" | python3 -c '
import json,sys
try:
    c = json.load(sys.stdin)["data"]["bestChain"][0]["protocolState"]["consensusState"]
    print(c["nextEpochData"]["ledger"]["hash"])
except Exception:
    sys.exit(1)
') || CHAIN_NEXT_HASH=""

  echo "$CHAIN_STAKING_HASH" | grep -qE "$LEDGER_HASH_PATTERN" || return 1
  case "$CHAIN_EPOCH" in ''|*[!0-9]*) return 1 ;; esac

  # An unsynced node describes a chain we are not following; its answer is not
  # a basis for skipping work or for naming an export.
  if [ "$CHAIN_SYNC_STATUS" != "SYNCED" ]; then
    log_warn "${node_url} reports syncStatus=${CHAIN_SYNC_STATUS}, not SYNCED"
    return 1
  fi
  return 0
}

# True when everything the chain currently advertises is already on disk.
nothing_to_do() {
  have_ledger_hash "$CHAIN_STAKING_HASH" || return 1
  [ "$EXPORT_NEXT_EPOCH" = "true" ] || return 0
  [ -z "$CHAIN_NEXT_HASH" ] && return 0
  have_ledger_hash "$CHAIN_NEXT_HASH"
}

have_ledger_hash() {
  ls "${LEDGERS_DIRECTORY}"/*-"$1".json.tar.gz >/dev/null 2>&1
}

publish_ledger() {
  which_ledger=$1
  epoch=$2
  expected_hash=${3:-}

  # The cheap path: the chain already told us which ledger is in force, and we
  # already have it. No export, no load on the daemon, nothing to discard.
  if [ -n "$expected_hash" ] && have_ledger_hash "$expected_hash"; then
    log "${which_ledger} (epoch ${epoch}) is already published as ${expected_hash}, nothing to do"
    return 0
  fi

  log "exporting ${which_ledger} (epoch ${epoch})"
  on_pod "/usr/local/bin/mina ledger export ${which_ledger} > /tmp/${which_ledger}.json" || return 1

  hash=$(on_pod "/usr/local/bin/mina ledger hash --ledger-file /tmp/${which_ledger}.json" \
    | tr -d '[:space:]' | grep -E "$LEDGER_HASH_PATTERN") \
    || { log_error "mina ledger hash returned no plausible hash for ${which_ledger}"; return 1; }
  log "  ledgerHash=${hash}"

  # An export that does not hash to what the chain advertised means the daemon
  # moved, or served a ledger for a different chain. Publishing it would put a
  # ledger no proposal can ever match into circulation.
  if [ -n "$expected_hash" ] && [ "$hash" != "$expected_hash" ]; then
    log_error "exported ${which_ledger} hashes to ${hash} but the chain advertises ${expected_hash} - discarding"
    on_pod "rm -f /tmp/${which_ledger}.json" || true
    return 1
  fi

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
  cat > "${LEDGERS_DIRECTORY}/.provider-status" <<EOF
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

  # Phase 1 - ask before doing. A cycle with nothing to do costs one GraphQL
  # query and touches no pod at all, which is the overwhelmingly common case:
  # an epoch lasts days, and polling is hourly.
  if [ -n "$MINA_NODE_URL" ] && chain_ledger_hashes "$MINA_NODE_URL"; then
    log "chain advertises epoch=${CHAIN_EPOCH} staking=${CHAIN_STAKING_HASH} next=${CHAIN_NEXT_HASH:-unknown}"
    if nothing_to_do; then
      log "already published; nothing to do"
      heartbeat
      return 0
    fi
  elif [ -n "$MINA_NODE_URL" ]; then
    log_warn "probe of ${MINA_NODE_URL} failed; falling back to inspecting pods directly"
  fi

  # Phase 2 - there is work, so pick a node and commit to it. The hashes are
  # re-read from that node rather than reused from the probe above: an export
  # has to be named and verified against the daemon that produced it.
  find_synced_pod || return 1
  read_epochs || return 1

  CHAIN_STAKING_HASH=""
  CHAIN_NEXT_HASH=""
  if [ -n "${SYNCED_POD_IP:-}" ] && chain_ledger_hashes "http://${SYNCED_POD_IP}:${MINA_GRAPHQL_PORT}/graphql"; then
    log "${SYNCED_POD} advertises staking=${CHAIN_STAKING_HASH} next=${CHAIN_NEXT_HASH:-unknown}"
    if nothing_to_do; then
      log "already published according to ${SYNCED_POD}; nothing to do"
      heartbeat
      return 0
    fi
  else
    log_warn "could not read ledger hashes from ${SYNCED_POD} on port ${MINA_GRAPHQL_PORT} - falling back to exporting first and hashing after, which is far more expensive"
  fi

  publish_ledger staking-epoch-ledger "$CURRENT_EPOCH" "$CHAIN_STAKING_HASH" || return 1

  if [ "$EXPORT_NEXT_EPOCH" = "true" ]; then
    # Not fatal: early in an epoch the daemon may not serve a next-epoch ledger
    # yet, and the current one is what is needed right now regardless.
    publish_ledger next-epoch-ledger "$NEXT_EPOCH" "$CHAIN_NEXT_HASH" \
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

  log "dir=${LEDGERS_DIRECTORY} nodeLabel=${MINA_NODE_LABEL} namespace=${MINA_NAMESPACE:-<release>} probe=${MINA_NODE_URL:-<none>} graphqlPort=${MINA_GRAPHQL_PORT} keepLastN=${KEEP_LAST_N}"

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

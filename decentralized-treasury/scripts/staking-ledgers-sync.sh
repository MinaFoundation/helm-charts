#!/bin/sh
# Mirrors staking ledger archives into the directory the voting-ledger-scheduler
# reads, as a content-addressed store:
#
#   <STAKING_LEDGERS_DIRECTORY>/<ledgerHash>.json    payload, named by its root
#   <STAKING_LEDGERS_DIRECTORY>/lifecycle-<id>.hash  pointer, one hash per line
#   <STAKING_LEDGERS_DIRECTORY>/.sync-status         liveness heartbeat
#
# WHY NOT EPOCH NUMBERS. Mina resets the epoch number to 0 at every hardfork,
# so an epoch identifies a ledger only within one era. mainnet demonstrates the
# failure: epoch 79's newest export is from 2024-06-04 while epoch 54's is from
# 2026-08-19, because the numbering reset at the June 2024 fork. Anything that
# picks "the highest epoch" therefore picks a ledger years out of date.
#
# The ledger hash is the stable identifier, and it is the one that is actually
# enforced: a proposal snapshots `stakingEpochData.ledger.hash` on-chain when it
# is created, and the treasury-proposal circuit asserts the hydrated ledger's
# Merkle root equals that snapshot. Hydrate a lifecycle from the wrong ledger
# and every proposal in it is unprovable - so this script resolves a hash per
# lifecycle first, and only then goes looking for an object carrying it.
#
# SLOT SCALES. Lifecycle ids are computed purely from `slotSinceGenesis`, which
# never resets, and TREASURY_DEPLOYED_AT_SLOT, which is on the same scale (it is
# what the contract's `globalSlotSinceGenesis.requireBetween` gates on). No
# hardfork offset appears in that arithmetic at all. The offset is derived only
# to sanity-check lifecycle/epoch alignment and to hint the listing prefix.
#
# THREE SOURCES, differing only in transport:
#   http  in-cluster staking-ledgers-fetcher, listed via nginx autoindex JSON
#   gcs   public GCS over anonymous HTTPS
#   s3    AWS, for releases whose ledgers already live there
# Object naming and unpacking are handled uniformly rather than per source, so
# adding a transport does not mean adding a parser. The produced-lifecycle check
# always uses AWS S3 whatever the ledger source, so this container needs IRSA in
# every case.
set -eu

STAKING_LEDGERS_DIRECTORY="${STAKING_LEDGERS_DIRECTORY:-/staking-ledgers}"
STAKING_LEDGERS_KEEP_LAST_N="${STAKING_LEDGERS_KEEP_LAST_N:-1}"
LIFECYCLE_IDS="${LIFECYCLE_IDS:-}"
SYNC_INTERVAL_SECONDS="${SYNC_INTERVAL_SECONDS:-300}"
SYNC_ONESHOT="${SYNC_ONESHOT:-false}"

STAKING_LEDGERS_SOURCE="${STAKING_LEDGERS_SOURCE:-gcs}"
STAKING_LEDGERS_BUCKET="${STAKING_LEDGERS_BUCKET:?Set STAKING_LEDGERS_BUCKET}"
STAKING_LEDGERS_PREFIX="${STAKING_LEDGERS_PREFIX:-}"

LIFECYCLE_PERIOD_DURATION="${LIFECYCLE_PERIOD_DURATION:?Set LIFECYCLE_PERIOD_DURATION}"
TREASURY_DEPLOYED_AT_SLOT="${TREASURY_DEPLOYED_AT_SLOT:-0}"
PERIODS_PER_LIFECYCLE="${PERIODS_PER_LIFECYCLE:-4}"

NETWORK="${NETWORK:?Set NETWORK}"
SQLITE_S3_PREFIX="s3://${SQLITE_S3_BUCKET:?Set SQLITE_S3_BUCKET}/${NETWORK}"

MINA_NODE_URL="${MINA_NODE_URL:?Set MINA_NODE_URL}"
API_URL="${API_URL:-}"
# Operator override, "12=jx...,13=jw...". Highest precedence, and the only way
# to resolve a lifecycle whose proposal period predates a hardfork.
LIFECYCLE_LEDGER_HASHES="${LIFECYCLE_LEDGER_HASHES:-}"
# When true, a lifecycle/epoch misalignment aborts instead of warning.
STRICT_ALIGNMENT="${STRICT_ALIGNMENT:-false}"

LEDGER_HASH_PATTERN='^j[1-9A-HJ-NP-Za-km-z]\{40,60\}$'

log()       { echo "[staking-ledgers-sync] $*"; }
log_warn()  { echo "[staking-ledgers-sync] WARN $*" >&2; }
log_error() { echo "[staking-ledgers-sync] ERROR $*" >&2; }

die() { log_error "$*"; exit 1; }

# ---------------------------------------------------------------- capabilities

require_tools() {
  for tool in curl python3; do
    command -v "$tool" >/dev/null 2>&1 || die "required tool '${tool}' is not on PATH"
  done
  # Needed for the produced-lifecycle check regardless of ledger source: that
  # check reads the sqlite bucket, which is always AWS.
  command -v aws >/dev/null 2>&1 || die "the produced-lifecycle check needs the aws CLI on PATH"
}

# JSON field extraction. Deliberately python3 rather than sed: a mis-parsed slot
# number silently selects the wrong lifecycle, which is exactly the class of
# failure this rewrite exists to remove. Prints nothing and returns 1 when the
# path is absent.
json_get() {
  python3 -c '
import json,sys
try:
    doc = json.load(sys.stdin)
except Exception:
    sys.exit(1)
cur = doc
for part in sys.argv[1].split("."):
    if isinstance(cur, list):
        try:
            cur = cur[int(part)]
        except (ValueError, IndexError):
            sys.exit(1)
        continue
    if not isinstance(cur, dict) or part not in cur:
        sys.exit(1)
    cur = cur[part]
if cur is None:
    sys.exit(1)
print(cur)
' "$1"
}

validate_uint() {
  case "$1" in
    ''|*[!0-9]*) return 1 ;;
  esac
  return 0
}

validate_ledger_hash() {
  echo "$1" | grep -q "$LEDGER_HASH_PATTERN"
}

# --------------------------------------------------------------- chain queries

CHAIN_EPOCH=""
CHAIN_SLOT=""
CHAIN_SLOT_SINCE_GENESIS=""
CHAIN_SLOTS_PER_EPOCH=""
CHAIN_STAKING_LEDGER_HASH=""
HARDFORK_SLOT_OFFSET=""

fetch_chain_state() {
  query='{"query":"{ daemonStatus { consensusConfiguration { slotsPerEpoch } } bestChain(maxLength:1) { protocolState { consensusState { epoch slot slotSinceGenesis stakingEpochData { ledger { hash } } } } } }"}'

  response=$(curl -sS --max-time 30 -X POST \
    -H 'Content-Type: application/json' \
    -d "$query" "$MINA_NODE_URL" 2>/dev/null) \
    || die "could not reach the Mina daemon at ${MINA_NODE_URL}"

  base="data.bestChain.0.protocolState.consensusState"
  CHAIN_EPOCH=$(printf '%s' "$response" | json_get "${base}.epoch") \
    || die "daemon response had no ${base}.epoch - is ${MINA_NODE_URL} a Mina GraphQL endpoint?"
  CHAIN_SLOT=$(printf '%s' "$response" | json_get "${base}.slot") || die "daemon response had no ${base}.slot"
  CHAIN_SLOT_SINCE_GENESIS=$(printf '%s' "$response" | json_get "${base}.slotSinceGenesis") \
    || die "daemon response had no ${base}.slotSinceGenesis"
  CHAIN_SLOTS_PER_EPOCH=$(printf '%s' "$response" | json_get "data.daemonStatus.consensusConfiguration.slotsPerEpoch") \
    || die "daemon response had no data.daemonStatus.consensusConfiguration.slotsPerEpoch"
  CHAIN_STAKING_LEDGER_HASH=$(printf '%s' "$response" | json_get "${base}.stakingEpochData.ledger.hash") \
    || die "daemon response had no ${base}.stakingEpochData.ledger.hash"

  for pair in "epoch:$CHAIN_EPOCH" "slot:$CHAIN_SLOT" \
              "slotSinceGenesis:$CHAIN_SLOT_SINCE_GENESIS" "slotsPerEpoch:$CHAIN_SLOTS_PER_EPOCH"; do
    name=${pair%%:*}
    value=${pair#*:}
    validate_uint "$value" || die "daemon returned a non-numeric ${name}: '${value}'"
  done
  validate_ledger_hash "$CHAIN_STAKING_LEDGER_HASH" \
    || die "daemon returned an implausible staking ledger hash: '${CHAIN_STAKING_LEDGER_HASH}'"

  [ "$CHAIN_SLOTS_PER_EPOCH" -gt 0 ] || die "daemon reported slotsPerEpoch=0"

  # slotSinceGenesis counts across hardforks; epoch/slot restart at each one.
  # The difference is how far the current era is offset from genesis.
  HARDFORK_SLOT_OFFSET=$(( CHAIN_SLOT_SINCE_GENESIS - (CHAIN_EPOCH * CHAIN_SLOTS_PER_EPOCH + CHAIN_SLOT) ))
  [ "$HARDFORK_SLOT_OFFSET" -ge 0 ] || die "derived a negative hardfork offset (${HARDFORK_SLOT_OFFSET}); the daemon's slot fields are inconsistent"
}

# Every proposal in a lifecycle must snapshot the same stakingEpochData, which
# holds only if the proposal period sits inside a single Mina epoch. That needs
# the lifecycle grid to line up with the epoch grid. Nothing else checks this,
# and getting it wrong makes the back half of each proposal period silently
# unprovable - so it is checked loudly on every start.
assert_alignment() {
  if [ "$LIFECYCLE_PERIOD_DURATION" -ne "$CHAIN_SLOTS_PER_EPOCH" ]; then
    message="lifecyclePeriodDuration=${LIFECYCLE_PERIOD_DURATION} != slotsPerEpoch=${CHAIN_SLOTS_PER_EPOCH}: a lifecycle period is not one Mina epoch, so proposals within one period can snapshot different staking ledgers"
    if [ "$STRICT_ALIGNMENT" = "true" ]; then die "$message"; fi
    log_warn "$message"
    return 0
  fi

  remainder=$(( (TREASURY_DEPLOYED_AT_SLOT - HARDFORK_SLOT_OFFSET) % CHAIN_SLOTS_PER_EPOCH ))
  [ "$remainder" -lt 0 ] && remainder=$(( remainder + CHAIN_SLOTS_PER_EPOCH ))

  if [ "$remainder" -ne 0 ]; then
    aligned=$(( TREASURY_DEPLOYED_AT_SLOT - remainder + CHAIN_SLOTS_PER_EPOCH ))
    message="treasuryDeployedAtSlot=${TREASURY_DEPLOYED_AT_SLOT} is not on an epoch boundary (offset by ${remainder} slots; hardforkOffset=${HARDFORK_SLOT_OFFSET}). Proposal periods straddle two Mina epochs, so proposals in the same lifecycle can snapshot different staking ledger hashes and the later ones become unprovable. Nearest aligned value above: ${aligned}"
    if [ "$STRICT_ALIGNMENT" = "true" ]; then die "$message"; fi
    log_warn "$message"
  fi
}

current_lifecycle_id() {
  # Pure globalSlotSinceGenesis arithmetic - the same scale the contract gates
  # on - so no hardfork offset is involved.
  if [ "$CHAIN_SLOT_SINCE_GENESIS" -lt "$TREASURY_DEPLOYED_AT_SLOT" ]; then
    echo "-1"
    return 0
  fi
  span=$(( LIFECYCLE_PERIOD_DURATION * PERIODS_PER_LIFECYCLE ))
  echo $(( (CHAIN_SLOT_SINCE_GENESIS - TREASURY_DEPLOYED_AT_SLOT) / span ))
}

# The Mina epoch a lifecycle's proposal period falls in, in the CURRENT era's
# numbering. Only a listing hint - it is meaningless across a hardfork, so the
# hash filter always decides.
epoch_hint_for_lifecycle() {
  lifecycle_id=$1
  span=$(( LIFECYCLE_PERIOD_DURATION * PERIODS_PER_LIFECYCLE ))
  start_slot=$(( TREASURY_DEPLOYED_AT_SLOT + lifecycle_id * span ))
  era_slot=$(( start_slot - HARDFORK_SLOT_OFFSET ))
  if [ "$era_slot" -lt 0 ]; then
    echo ""
    return 0
  fi
  echo $(( era_slot / CHAIN_SLOTS_PER_EPOCH ))
}

# ------------------------------------------------------------ hash resolution

hash_from_override() {
  lifecycle_id=$1
  [ -n "$LIFECYCLE_LEDGER_HASHES" ] || return 1
  value=$(echo "$LIFECYCLE_LEDGER_HASHES" | tr ',' '\n' \
    | sed -n "s/^[[:space:]]*${lifecycle_id}=//p" | head -n1 | tr -d '[:space:]')
  [ -n "$value" ] || return 1
  validate_ledger_hash "$value" \
    || die "LIFECYCLE_LEDGER_HASHES has an invalid hash for lifecycle ${lifecycle_id}: '${value}'"
  echo "$value"
}

# The value the circuit will compare against: whatever the lifecycle's own
# proposals snapshotted on-chain at creation.
hash_from_api() {
  lifecycle_id=$1
  [ -n "$API_URL" ] || return 1
  response=$(curl -sS --max-time 20 "${API_URL}/proposals?lifecycleId=${lifecycle_id}" 2>/dev/null) || return 1

  value=$(printf '%s' "$response" | python3 -c '
import json,sys
try:
    doc = json.load(sys.stdin)
except Exception:
    sys.exit(1)

def walk(node):
    if isinstance(node, dict):
        for key, item in node.items():
            if key == "stakingEpochDataLedgerHash" and isinstance(item, str) and item:
                yield item
            else:
                yield from walk(item)
    elif isinstance(node, list):
        for item in node:
            yield from walk(item)

found = sorted(set(walk(doc)))
if not found:
    sys.exit(1)
# Disagreement here means the lifecycle straddles an epoch boundary - exactly
# what assert_alignment warns about. Refuse rather than pick one arbitrarily.
if len(found) > 1:
    sys.stderr.write("multiple distinct staking ledger hashes: %s\n" % ", ".join(found))
    sys.exit(2)
print(found[0])
') || {
    status=$?
    if [ "$status" -eq 2 ]; then
      die "lifecycle ${lifecycle_id} has proposals snapshotting DIFFERENT staking ledger hashes - the lifecycle grid is misaligned with the Mina epoch grid and this lifecycle cannot be built correctly"
    fi
    return 1
  }

  validate_ledger_hash "$value" || return 1
  echo "$value"
}

# Only valid for the lifecycle whose proposal period is open right now: outside
# it the daemon reports a different epoch's ledger.
hash_from_daemon() {
  lifecycle_id=$1
  current=$(current_lifecycle_id)
  [ "$lifecycle_id" -eq "$current" ] || return 1

  span=$(( LIFECYCLE_PERIOD_DURATION * PERIODS_PER_LIFECYCLE ))
  start_slot=$(( TREASURY_DEPLOYED_AT_SLOT + lifecycle_id * span ))
  proposal_period_end=$(( start_slot + LIFECYCLE_PERIOD_DURATION ))
  if [ "$CHAIN_SLOT_SINCE_GENESIS" -ge "$proposal_period_end" ]; then
    return 1
  fi

  echo "$CHAIN_STAKING_LEDGER_HASH"
}

resolve_hash_for_lifecycle() {
  lifecycle_id=$1

  if value=$(hash_from_override "$lifecycle_id"); then
    echo "$value override"
    return 0
  fi
  if value=$(hash_from_api "$lifecycle_id"); then
    echo "$value api"
    return 0
  fi
  if value=$(hash_from_daemon "$lifecycle_id"); then
    echo "$value daemon"
    return 0
  fi
  return 1
}

# -------------------------------------------------------------- source adapter

gcs_list_keys() {
  marker=""
  page=0
  while [ "$page" -lt 50 ]; do
    url="https://storage.googleapis.com/${STAKING_LEDGERS_BUCKET}?max-keys=1000"
    [ -n "$STAKING_LEDGERS_PREFIX" ] && url="${url}&prefix=${STAKING_LEDGERS_PREFIX}"
    [ -n "$marker" ] && url="${url}&marker=${marker}"

    body=$(curl -sS --max-time 60 "$url") || return 1
    printf '%s' "$body" | tr '<' '\n' | sed -n 's/^Key>//p'

    marker=$(printf '%s' "$body" | tr '<' '\n' | sed -n 's/^NextMarker>//p' | head -n1)
    [ -n "$marker" ] || break
    marker=$(printf '%s' "$marker" | sed 's/ /%20/g')
    page=$(( page + 1 ))
  done
}

s3_list_keys() {
  aws s3 ls "s3://${STAKING_LEDGERS_BUCKET}/${STAKING_LEDGERS_PREFIX}/" | awk '{ print $4 }' | grep -v '^$'
}

# Filename parsing is deliberately NOT positional. At least three layouts are in
# use for the same thing:
#
#   staking-<epoch>-<hash>-<md5>-<YYYY-MM-DD>_<HHMM>.json   o1-labs, GCS
#   <epoch>-<hash>.tar.gz                                   legacy, S3
#   <network>-<epoch>-<hash>.json.tar.gz                    mina-staking-ledgers-exporter, S3
#
# Any positional rule breaks on the next one. Instead the key is split on
# non-alphanumerics and the first token shaped like a Mina ledger hash wins,
# which reads all three and tolerates a fourth. A false positive would have to
# be a valid base58 ledger hash that also equals the hash being searched for, so
# the subsequent match is what makes this safe rather than merely convenient.
key_ledger_hash() {
  printf '%s' "$1" | tr -c '[:alnum:]' '\n' \
    | grep "^j[1-9A-HJ-NP-Za-km-z]\{40,60\}$" | head -n1
}

# Optional integrity check; only the GCS layout carries one.
key_md5() {
  printf '%s' "$1" | tr -c '[:alnum:]' '\n' | grep "^[0-9a-f]\{32\}$" | head -n1
}

# Tiebreak when several objects carry the same ledger hash (the GCS layout
# re-exports daily). Lexicographic order on YYYY-MM-DD_HHMM is chronological.
# Layouts without a timestamp publish one object per hash, so an empty key is
# correct rather than merely tolerable.
key_sort_key() {
  printf '%s' "$1" | sed -n 's/.*\([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]_[0-9][0-9][0-9][0-9]\).*/\1/p'
}

# In-cluster HTTP source (staking-ledgers-fetcher): the bucket value is a base
# URL and the listing is nginx's `autoindex_format json`. Nothing leaves the
# cluster, which is the point - no object store is involved at all.
http_list_keys() {
  body=$(curl -sS --max-time 60 "${STAKING_LEDGERS_BUCKET%/}/") || return 1
  printf '%s' "$body" | python3 -c '
import json,sys
try:
    entries = json.load(sys.stdin)
except Exception:
    sys.exit(1)
for entry in entries:
    name = entry.get("name")
    if name and entry.get("type", "file") == "file":
        print(name)
'
}

http_fetch() {
  curl -sS --max-time 3600 --fail -o "$2" "${STAKING_LEDGERS_BUCKET%/}/$1"
}

gcs_fetch() {
  curl -sS --max-time 3600 -o "$2" "https://storage.googleapis.com/${STAKING_LEDGERS_BUCKET}/$1"
}

s3_fetch() {
  key_path=$1
  [ -n "$STAKING_LEDGERS_PREFIX" ] && key_path="${STAKING_LEDGERS_PREFIX}/$1"
  aws s3 cp "s3://${STAKING_LEDGERS_BUCKET}/${key_path}" "$2" --only-show-errors
}

source_list_keys() {
  case "$STAKING_LEDGERS_SOURCE" in
    gcs)  gcs_list_keys ;;
    s3)   s3_list_keys ;;
    http) http_list_keys ;;
  esac
}

source_fetch() {
  case "$STAKING_LEDGERS_SOURCE" in
    gcs)  gcs_fetch "$1" "$2" ;;
    s3)   s3_fetch "$1" "$2" ;;
    http) http_fetch "$1" "$2" ;;
  esac
}

# Download, then unpack based on what the object actually is rather than on
# which bucket it came from - .tar.gz appears on S3 in two different layouts and
# nothing stops a plain .json appearing there too.
source_install() {
  key=$1
  destination=$2

  tmp_dir=$(mktemp -d)
  if ! source_fetch "$key" "${tmp_dir}/download"; then
    rm -rf "$tmp_dir"
    return 1
  fi

  case "$key" in
    *.tar.gz|*.tgz)
      # tar and gzip are both absent from the aws-cli image, so this goes
      # through python3. The member name is not assumed: the layouts variously
      # call it <epoch>.json and <network>-<epoch>-<hash>.json.
      if ! python3 -c '
import sys, tarfile
archive, destination = sys.argv[1], sys.argv[2]
with tarfile.open(archive, "r:gz") as tar:
    members = [m for m in tar.getmembers() if m.isfile() and m.name.endswith(".json")]
    if len(members) != 1:
        sys.stderr.write("expected exactly one .json member, found %d: %s\n"
                         % (len(members), [m.name for m in members]))
        sys.exit(1)
    source = tar.extractfile(members[0])
    with open(destination, "wb") as out:
        while True:
            chunk = source.read(1024 * 1024)
            if not chunk:
                break
            out.write(chunk)
' "${tmp_dir}/download" "${tmp_dir}/unpacked"; then
        rm -rf "$tmp_dir"
        return 1
      fi
      mv "${tmp_dir}/unpacked" "$destination"
      ;;
    *)
      mv "${tmp_dir}/download" "$destination"
      ;;
  esac

  rm -rf "$tmp_dir"
}

# ------------------------------------------------------------------- selection

LISTED_COUNT=0
UNPARSEABLE_COUNT=0
UNPARSEABLE_SAMPLE=""

# Prints the best object key carrying $1, or returns 1. Counts everything it
# rejects so a format change surfaces as numbers rather than silence.
select_object_for_hash() {
  wanted_hash=$1
  keys=$2

  matched_pairs=""
  seen_md5=""
  matches=0

  for key in $keys; do
    [ -n "$key" ] || continue
    hash=$(key_ledger_hash "$key")
    if ! validate_ledger_hash "$hash"; then
      UNPARSEABLE_COUNT=$(( UNPARSEABLE_COUNT + 1 ))
      [ -z "$UNPARSEABLE_SAMPLE" ] && UNPARSEABLE_SAMPLE=$key
      continue
    fi
    [ "$hash" = "$wanted_hash" ] || continue

    matches=$(( matches + 1 ))
    md5=$(key_md5 "$key")
    if [ -n "$md5" ]; then
      if [ -z "$seen_md5" ]; then
        seen_md5=$md5
      elif [ "$seen_md5" != "$md5" ]; then
        log_error "objects for ledger ${wanted_hash} disagree on checksum (${seen_md5} vs ${md5}) - refusing to choose between them"
        return 1
      fi
    fi

    # Collected rather than compared inline: POSIX `[` has no defined string
    # ordering operator, so the newest is picked with sort(1) below. The sort
    # key is YYYY-MM-DD_HHMM, where lexicographic order is chronological order.
    matched_pairs="${matched_pairs}$(key_sort_key "$key") ${key}
"
  done

  [ "$matches" -gt 0 ] || return 1
  printf '%s' "$matched_pairs" | grep -v '^$' | sort | tail -n1 | cut -d' ' -f2-
}

verify_checksum() {
  path=$1
  expected=$2
  [ -n "$expected" ] || return 0
  command -v md5sum >/dev/null 2>&1 || return 0
  actual=$(md5sum "$path" | cut -d' ' -f1)
  [ "$actual" = "$expected" ]
}

# --------------------------------------------------------------- produced set

# Unchanged, and deliberately still AWS for every source: the published
# <lifecycleId>.sqlite object IS the product, so once it lands the input is no
# longer needed. Keyed on the published object rather than the local .done
# marker, which is written before the push.
produced_lifecycle_ids() {
  aws s3 ls "${SQLITE_S3_PREFIX}/" 2>/dev/null \
    | awk '{ print $4 }' \
    | sed -n 's/^\([0-9][0-9]*\)\.sqlite$/\1/p'
}

wanted_lifecycles() {
  produced=$1

  if [ -n "$LIFECYCLE_IDS" ]; then
    echo "$LIFECYCLE_IDS" | tr ',' '\n' | while read -r id; do
      id=$(printf '%s' "$id" | tr -d '[:space:]')
      [ -n "$id" ] || continue
      validate_uint "$id" || { log_warn "ignoring non-numeric entry in LIFECYCLE_IDS: '${id}'"; continue; }
      echo "$produced" | grep -qx "$id" && continue
      echo "$id"
    done
    return 0
  fi

  tip=$(current_lifecycle_id)
  if [ "$tip" -lt 0 ]; then
    log "treasury has not started yet (slotSinceGenesis=${CHAIN_SLOT_SINCE_GENESIS} < treasuryDeployedAtSlot=${TREASURY_DEPLOYED_AT_SLOT})"
    return 0
  fi

  floor=0
  if [ "$STAKING_LEDGERS_KEEP_LAST_N" -gt 0 ]; then
    floor=$(( tip - STAKING_LEDGERS_KEEP_LAST_N + 1 ))
    [ "$floor" -lt 0 ] && floor=0
  fi

  id=$tip
  while [ "$id" -ge "$floor" ]; do
    echo "$produced" | grep -qx "$id" || echo "$id"
    id=$(( id - 1 ))
  done
}

# ------------------------------------------------------------------- the store

prune_store() {
  wanted_hashes=$1

  for path in "$STAKING_LEDGERS_DIRECTORY"/*; do
    [ -e "$path" ] || continue
    name=$(basename "$path")
    case "$name" in
      .sync-status) continue ;;
      lifecycle-*.hash)
        id=${name#lifecycle-}; id=${id%.hash}
        printf '%s\n' "$wanted_hashes" | grep -q "^${id} " && continue
        log "dropping pointer ${name} (no longer wanted)"
        rm -f "$path"
        continue
        ;;
      *.json)
        hash=${name%.json}
        printf '%s\n' "$wanted_hashes" | awk '{print $2}' | grep -qx "$hash" && continue
        log "discarding ${name} (voting ledger published, or outside the window)"
        rm -f "$path"
        continue
        ;;
      *.part) rm -f "$path"; continue ;;
    esac
    log_warn "removing unrecognised file in the ledger store: ${name}"
    rm -f "$path"
  done
}

sync_once() {
  mkdir -p "$STAKING_LEDGERS_DIRECTORY"

  fetch_chain_state
  assert_alignment

  UNPARSEABLE_COUNT=0
  UNPARSEABLE_SAMPLE=""

  produced=$(produced_lifecycle_ids || true)
  lifecycles=$(wanted_lifecycles "$produced")

  if [ -z "$lifecycles" ]; then
    log "nothing to fetch: every lifecycle in the window already has a voting ledger in ${SQLITE_S3_PREFIX}"
    prune_store ""
    heartbeat 0 0
    return 0
  fi

  keys=$(source_list_keys) || { log_error "could not list ${STAKING_LEDGERS_SOURCE} bucket ${STAKING_LEDGERS_BUCKET}"; return 1; }
  LISTED_COUNT=$(printf '%s\n' "$keys" | grep -c '^.' || true)

  resolved=""       # "<lifecycleId> <hash>" per line
  unresolved=""
  fetched=0

  for lifecycle_id in $lifecycles; do
    if ! resolution=$(resolve_hash_for_lifecycle "$lifecycle_id"); then
      unresolved="${unresolved}${lifecycle_id}:no-hash "
      continue
    fi
    hash=${resolution%% *}
    via=${resolution##* }

    key=$(select_object_for_hash "$hash" "$keys") || {
      log_error "lifecycle ${lifecycle_id} needs ledger ${hash} (resolved via ${via}), but no object in ${STAKING_LEDGERS_BUCKET} carries that hash (${LISTED_COUNT} keys listed)"
      unresolved="${unresolved}${lifecycle_id}:no-object "
      continue
    }

    resolved="${resolved}${lifecycle_id} ${hash}
"
    destination="${STAKING_LEDGERS_DIRECTORY}/${hash}.json"

    if [ ! -f "$destination" ]; then
      log "fetching ${key} for lifecycleId=${lifecycle_id} (ledgerHash=${hash}, via=${via})"
      if ! source_install "$key" "$destination"; then
        log_error "failed to fetch ${key} for lifecycle ${lifecycle_id}"
        rm -f "${destination}.part"
        continue
      fi
      if ! verify_checksum "$destination" "$(key_md5 "$key")"; then
        log_error "checksum mismatch on ${key} - discarding the partial download"
        rm -f "$destination"
        continue
      fi
      fetched=$(( fetched + 1 ))
    fi

    printf '%s\n' "$hash" > "${STAKING_LEDGERS_DIRECTORY}/lifecycle-${lifecycle_id}.hash"
  done

  prune_store "$resolved"

  selected=$(printf '%s' "$resolved" | grep -c '^.' || true)
  log "cycle summary: listed=${LISTED_COUNT} selected=${selected} fetched=${fetched} unparseable=${UNPARSEABLE_COUNT} unresolved=[${unresolved% }]"

  # Keys that parse as nothing while nothing matches is the exact signature of
  # an upstream naming change - the failure that used to look like a healthy
  # pod doing nothing forever.
  if [ "$UNPARSEABLE_COUNT" -gt 0 ] && [ "$selected" -eq 0 ]; then
    log_error "every listed key failed to parse as ${STAKING_LEDGERS_SOURCE} (e.g. '${UNPARSEABLE_SAMPLE}') and nothing was selected - the bucket layout has probably changed"
    return 1
  fi

  heartbeat "$selected" "$fetched"
}

heartbeat() {
  cat > "${STAKING_LEDGERS_DIRECTORY}/.sync-status" <<EOF
{
  "lastSuccessEpochSeconds": $(date +%s),
  "lastSuccessAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "selected": ${1},
  "fetched": ${2}
}
EOF
}

main() {
  require_tools

  case "$STAKING_LEDGERS_SOURCE" in
    gcs|s3|http) ;;
    *) die "STAKING_LEDGERS_SOURCE must be 'gcs', 's3' or 'http', got '${STAKING_LEDGERS_SOURCE}'" ;;
  esac

  log "source=${STAKING_LEDGERS_SOURCE} bucket=${STAKING_LEDGERS_BUCKET} prefix='${STAKING_LEDGERS_PREFIX}' dir=${STAKING_LEDGERS_DIRECTORY}"
  log "network=${NETWORK} lifecyclePeriodDuration=${LIFECYCLE_PERIOD_DURATION} periodsPerLifecycle=${PERIODS_PER_LIFECYCLE} treasuryDeployedAtSlot=${TREASURY_DEPLOYED_AT_SLOT}"
  if [ -n "$LIFECYCLE_IDS" ]; then
    log "lifecycleIds=[${LIFECYCLE_IDS}] (explicit list overrides the keep-last-N window)"
  else
    log "keepLastN=${STAKING_LEDGERS_KEEP_LAST_N}"
  fi

  if [ "$SYNC_ONESHOT" = "true" ]; then
    sync_once
    log "initial sync complete"
    return 0
  fi

  while true; do
    sync_once || log_warn "sync cycle failed, retrying in ${SYNC_INTERVAL_SECONDS}s"
    sleep "$SYNC_INTERVAL_SECONDS"
  done
}

case "${1:-}" in
  resolve-hash)
    # Debug helper: what would this lifecycle resolve to, and to which object?
    require_tools
    lifecycle_id="${2:?Usage: staking-ledgers-sync.sh resolve-hash <lifecycle-id>}"
    fetch_chain_state
    log "chain: epoch=${CHAIN_EPOCH} slot=${CHAIN_SLOT} slotSinceGenesis=${CHAIN_SLOT_SINCE_GENESIS} slotsPerEpoch=${CHAIN_SLOTS_PER_EPOCH} hardforkOffset=${HARDFORK_SLOT_OFFSET}"
    log "currentLifecycleId=$(current_lifecycle_id) epochHint=$(epoch_hint_for_lifecycle "$lifecycle_id")"
    if resolution=$(resolve_hash_for_lifecycle "$lifecycle_id"); then
      log "lifecycle ${lifecycle_id} -> ${resolution%% *} (via ${resolution##* })"
      keys=$(source_list_keys)
      if key=$(select_object_for_hash "${resolution%% *}" "$keys"); then
        log "object: ${key}"
      else
        log_error "no object carries that hash"
        exit 1
      fi
    else
      log_error "could not resolve a ledger hash for lifecycle ${lifecycle_id}"
      exit 1
    fi
    ;;
  "") main ;;
  *) echo "Usage: staking-ledgers-sync.sh [resolve-hash <lifecycle-id>]" >&2; exit 64 ;;
esac

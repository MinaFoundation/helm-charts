#!/usr/bin/env bash

# This script is used to populate a postgres database with missing precomputed archiveDB blocks

set -e
set -o pipefail

main() {
  info "Script started"

  if [ -z "$PG_CONN" ]; then
    echo "The PG_CONN environment variable is not set or is empty."
    exit 1
  fi

  if [[ "$GUARDIAN_AUTO_IMPORT_URL" != "" ]]; then
    echo Adding block "$GUARDIAN_AUTO_IMPORT_URL"
    insert_block "$GUARDIAN_AUTO_IMPORT_URL"
  fi

  if db_has_no_missing_blocks; then
    info "Database has no missing blocks"
    exit 0
  fi

  info "Top 10 blocks in the archiveDB:"
  get_top10_blocks

  info "Get current missing blocks information:"
  fetch_mina_missing_blocks | jq -rs .[].message

  info "Restoring blocks individually from: ${GUARDIAN_PRECOMPUTED_BLOCKS_URL}"
  while true; do
    MISSING_BLOCKS=$(fetch_mina_missing_blocks)
    PARENT_HASH="$(get_parent_hash "$MISSING_BLOCKS")"
    PARENT_HEIGHT="$(get_parent_height "$MISSING_BLOCKS")"
    GAPS_TOTAL="$(get_gaps_total "$MISSING_BLOCKS")"
    PARENT_BLOCK_URL="${GUARDIAN_PRECOMPUTED_BLOCKS_URL}/${MINA_NETWORK}-${PARENT_HEIGHT}-${PARENT_HASH}.json"

    [[ "$PARENT_HASH" == "null" ]] && info "No more missing blocks found" && break

    info "Inserting block $PARENT_HEIGHT ($GAPS_TOTAL left): $PARENT_BLOCK_URL"
    insert_block "$PARENT_BLOCK_URL"
  done

  get_top10_blocks
  info "Database has no missing blocks, back to genesis!"
}

db_has_no_missing_blocks() {
  mina-missing-blocks-auditor --archive-uri "$PG_CONN" 1> /dev/null
}

fetch_mina_missing_blocks() {
  # Ignore the return error exit code when missing blocks
  mina-missing-blocks-auditor --archive-uri "$PG_CONN" || true
}

get_parent_hash() {
  jq -rs 'map(select(.metadata.parent_hash != null and .metadata.parent_height != null)) | sort_by(.metadata.height) | .[0].metadata.parent_hash' <<< "$1"
}

get_parent_height() {
  jq -rs 'map(select(.metadata.parent_hash != null and .metadata.parent_height != null)) | sort_by(.metadata.height) | .[0].metadata.parent_height' <<< "$1"
}

get_gaps_total() {
  jq -rs 'map(select(.metadata.parent_hash != null and .metadata.parent_height != null)) | [.[].metadata.missing_blocks_gap] | add' <<< "$1"
}

insert_block() {
  PARENT_BLOCK_URL="$1"
  mina-archive-blocks --precomputed --archive-uri "$PG_CONN" \
    <(curl -s "$PARENT_BLOCK_URL") \
    | jq -rs '"[BOOTSTRAP] Populated database with block: \(.[-1].message)"'
}

get_top10_blocks() {
  psql "${PG_CONN}" -c "SELECT state_hash,height FROM blocks ORDER BY height DESC LIMIT 10"
}

info() {
  echo "[BOOTSTRAP]" "$@"
}

main

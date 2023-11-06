#!/usr/bin/env bash

# This script is adapted from https://github.com/MinaProtocol/mina/blob/develop/src/app/rosetta/download-missing-blocks.sh
# It is used to populate a postgres database with missing precomputed archiveDB blocks

if [ -z "$DB_USERNAME" ]; then
    echo "The DB_USERNAME environment variable is not set or is empty."
    exit 1
fi

if [ -z "$PGPASSWORD" ]; then
    echo "The PGPASSWORD environment variable is not set or is empty."
    exit 1
fi

if [ -z "$DB_HOST" ]; then
    echo "The DB_HOST environment variable is not set or is empty."
    exit 1
fi

if [ -z "$DB_PORT" ]; then
    echo "The DB_PORT environment variable is not set or is empty."
    exit 1
fi

if [ -z "$DB_NAME" ]; then
    echo "The DB_NAME environment variable is not set or is empty."
    exit 1
fi

if [ -z "$PRECOMPUTED_BLOCKS_URL" ]; then
    echo "The PRECOMPUTED_BLOCKS_URL environment variable is not set or is empty."
    exit 1
fi

PG_CONN=postgres://${DB_USERNAME}:${PGPASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}

function jq_parent_json() {
   jq -rs 'map(select(.metadata.parent_hash != null and .metadata.parent_height != null)) | "\(.[0].metadata.parent_height)-\(.[0].metadata.parent_hash).json"'
}

function jq_parent_hash() {
   jq -rs 'map(select(.metadata.parent_hash != null and .metadata.parent_height != null)) | .[0].metadata.parent_hash'
}

function populate_db() {
   mina-archive-blocks --precomputed --archive-uri "${1}" "${2}" | jq -rs '"[BOOTSTRAP] Populated database with block: \(.[-1].message)"'
   rm "${2}"
}

function download_block() {
    echo "Downloading ${1} block"
    curl -sO "${PRECOMPUTED_BLOCKS_URL}/${1}"
}

HASH='map(select(.metadata.parent_hash != null and .metadata.parent_height != null)) | .[0].metadata.parent_hash'
# Bootstrap finds every missing state hash in the database and imports them from the o1labs bucket of .json blocks
function bootstrap() {
  echo "[BOOTSTRAP] Top 10 blocks before bootstrapping the archiveDB:"
  psql "${PG_CONN}" -c "SELECT state_hash,height FROM blocks ORDER BY height DESC LIMIT 10"
  echo "[BOOTSTRAP] Restoring blocks individually from ${PRECOMPUTED_BLOCKS_URL}..."

  until [[ "$PARENT" == "null" ]] ; do
    PARENT_FILE="${MINA_NETWORK}-$(mina-missing-blocks-auditor --archive-uri $PG_CONN | jq_parent_json)"
    download_block "${PARENT_FILE}"
    populate_db "$PG_CONN" "$PARENT_FILE"
    PARENT="$(mina-missing-blocks-auditor --archive-uri $PG_CONN | jq_parent_hash)"
  done

  echo "[BOOTSTRAP] Top 10 blocks in bootstrapped archiveDB:"
  psql "${PG_CONN}" -c "SELECT state_hash,height FROM blocks ORDER BY height DESC LIMIT 10"
  echo "[BOOTSTRAP] This Archive node is synced with no missing blocks back to genesis!"

  echo "[BOOTSTRAP] Checking again in 60 minutes..."
  sleep 3000
}

# Wait until there is a block missing
PARENT=null
while true; do # Test once every 10 minutes forever, take an hour off when bootstrap completes
  PARENT="$(mina-missing-blocks-auditor --archive-uri $PG_CONN | jq_parent_hash)"
  echo "[BOOTSTRAP] $(mina-missing-blocks-auditor --archive-uri $PG_CONN | jq -rs .[].message)"
  [[ "$PARENT" != "null" ]] && echo "[BOOSTRAP] Some blocks are missing, moving to recovery logic..." && bootstrap
  sleep 600 # Wait for the daemon to catchup and start downloading new blocks
done
echo "[BOOTSTRAP] This Archive node is synced with no missing blocks back to genesis!"

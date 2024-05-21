#!/usr/bin/env bash

set -e

main() {
  echo "INFO: Dump exporter init script started"
  /scripts/wait-for-db.sh

  echo "INFO: Checking if database has missing blocks"
  retry_while db_has_no_missing_blocks 2880 5 # Retries every 5 seconds for 4 hours
  echo "INFO: Database has no missing blocks, back to genesis!"

  echo "INFO: Dump exporter init script complete"
}

db_has_no_missing_blocks() {
  mina-missing-blocks-auditor --archive-uri "$PG_CONN" 1> /dev/null
}

retry_while() {
  local -r cmd="${1:?cmd is missing}"
  local -r retries="${2:-300}"
  local -r sleep_time="${3:-1}"
  local return_value=1

  read -r -a command <<< "$cmd"
  for ((i = 1; i <= retries; i += 1)); do
    "${command[@]}" && return_value=0 && break
    echo "Retrying in $sleep_time second(s) [$i/$retries]..."
    sleep "$sleep_time"
  done
  return $return_value
}

main

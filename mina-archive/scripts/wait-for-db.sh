#!/usr/bin/env bash

set -e

DB_BOOTSTRAP_LOCKING_DATABASE_NAME=${DB_BOOTSTRAP_LOCKING_DATABASE_NAME:-bootstrapping_lock}
DB_BOOTSTRAP_TIMEOUT_SEC=${DB_BOOTSTRAP_TIMEOUT_SEC:-1800} # 30 min

BOOTSTRAP_SLEEP_TIME_SEC=5
BOOTSTRAP_RETRIES=$((DB_BOOTSTRAP_TIMEOUT_SEC / BOOTSTRAP_SLEEP_TIME_SEC))

main() {
  info "Wait for DB started"
  info "Host: $PGHOST"
  info "Port: $PGPORT"
  info "User: $PGUSER"
  info "Database: $PGDATABASE"
  info "Locking database: $DB_BOOTSTRAP_LOCKING_DATABASE_NAME"

  info "Checking if database server is online"
  retry_while check_database_is_online 120 1 # 2 min
  info "Database is online"

  info "Checking if bootstrap is done"
  retry_while check_bootstrap_is_done "$BOOTSTRAP_RETRIES" "$BOOTSTRAP_SLEEP_TIME_SEC"
  info "Database is online and ready to use!"
}

check_database_is_online() {
  check_database_connection || error -n "INFO: Database server is offline. "
}

check_bootstrap_is_done() {
  (check_database_connection && ! check_locking_database_is_present) \
    || error -n "INFO: Database is online but the bootsrap lock ($DB_BOOTSTRAP_LOCKING_DATABASE_NAME) is still present. "
}

check_database_connection() {
  timeout 1 psql "$PGDATABASE" -l > /dev/null 2>&1
}

check_locking_database_is_present() {
  timeout 1 psql "$DB_BOOTSTRAP_LOCKING_DATABASE_NAME" -l > /dev/null 2>&1
}

info() {
  echo "INFO: $*"
}

error() {
  echo "$@"
  return 1
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

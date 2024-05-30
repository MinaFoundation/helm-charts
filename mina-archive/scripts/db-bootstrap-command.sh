#!/usr/bin/env bash

set -e

DB_BOOTSTRAP_CREATE_DATABASE=${DB_BOOTSTRAP_CREATE_DATABASE:-false}
DB_BOOTSTRAP_CSV_EXTRA_SQL_FILE_URLS=${DB_BOOTSTRAP_CSV_EXTRA_SQL_FILE_URLS:-}
DB_BOOTSTRAP_CSV_SQL_FILE_URLS=${DB_BOOTSTRAP_CSV_SQL_FILE_URLS:-}
DB_BOOTSTRAP_LOCKING_DATABASE_NAME=${DB_BOOTSTRAP_LOCKING_DATABASE_NAME:-bootstrapping_lock}
DB_BOOTSTRAP_POST_CUSTOM_SQL=${DB_BOOTSTRAP_POST_CUSTOM_SQL:-}
DB_BOOTSTRAP_PRE_CUSTOM_SQL=${DB_BOOTSTRAP_PRE_CUSTOM_SQL:-}

main() {
  info "Database bootstrap started"
  info "Host: $PGHOST"
  info "Port: $PGPORT"
  info "User: $PGUSER"
  info "Database: $PGDATABASE"
  info "Locking database: $DB_BOOTSTRAP_LOCKING_DATABASE_NAME"

  cd "$(mktemp -d)"

  info "Checking database server connection"
  wait_db_server || error "Timeout on waiting database server connection"

  info "Checking if database already exists"
  if check_db_exists; then
    if check_db_is_valid; then
      info "Database already exists and looks valid, exit"
      exit
    else
      error "Database already exists but looks invalid"
      exit 1
    fi
  fi

  info "Adding bootstrap locking database"
  add_locking_db

  if [[ $DB_BOOTSTRAP_CREATE_DATABASE == "true" ]]; then
    info "Creating database"
    create_database || error "Fail to create database"
  fi

  if [[ $DB_BOOTSTRAP_PRE_CUSTOM_SQL != "" ]]; then
    info "Running pre custom SQL:"
    info "$DB_BOOTSTRAP_PRE_CUSTOM_SQL"
    run_pre_custom_sql || error "Failed on running pre custom SQL"
  fi

  info "Fetching remote extra SQL files"
  fetch_extra_sql_files || error "Failed on fetching extra SQL files"

  info "Running remote SQL files"
  run_sql_files || error "Failed on running SQL files"

  if [[ $DB_BOOTSTRAP_POST_CUSTOM_SQL != "" ]]; then
    info "Running post custom SQL:"
    info "$DB_BOOTSTRAP_POST_CUSTOM_SQL"
    run_post_custom_sql || error "Failed on running post custom SQL"
  fi


  info "Checking the database"
  if ! check_db_is_valid; then
    error "Database looks invalid, blocks table is missing, error"
  fi;

  info "Removing bootstrap locking database"
  remove_locking_db

  info "Database looks valid, boostrap complete, exit"
}

wait_db_server() {
  retry_while check_db_server_is_online
}

check_db_server_is_online() {
  timeout 1 psql postgres -c 'SELECT 1' > /dev/null 2>&1
}

check_db_exists() {
  psql -c 'SELECT 1' > /dev/null 2>&1
}

create_database() {
  psql postgres -c "CREATE DATABASE $PGDATABASE"
}

check_db_is_valid() {
  psql -c 'SELECT FROM blocks'
}

check_locking_db_exists() {
  psql "$DB_BOOTSTRAP_LOCKING_DATABASE_NAME" -c 'SELECT 1' > /dev/null 2>&1
}

add_locking_db() {
  if ! check_locking_db_exists; then
    psql postgres -c "CREATE DATABASE $DB_BOOTSTRAP_LOCKING_DATABASE_NAME"
  fi
}

remove_locking_db() {
  psql postgres -c "DROP DATABASE $DB_BOOTSTRAP_LOCKING_DATABASE_NAME"
}

run_pre_custom_sql() {
  echo "$DB_BOOTSTRAP_PRE_CUSTOM_SQL" | psql --set=ON_ERROR_STOP=1 -f -
}

run_post_custom_sql() {
  echo "$DB_BOOTSTRAP_POST_CUSTOM_SQL" | psql --set=ON_ERROR_STOP=1 -f -
}

fetch_extra_sql_files() {
  URLS=${DB_BOOTSTRAP_CSV_EXTRA_SQL_FILE_URLS//,/ }

  for URL in $URLS; do
    info "Downloading $URL"
    curl "$URL" -sO --fail || { error "Unable to download the URL $URL"; return 1; }
  done
}

run_sql_files() {
  URLS="${DB_BOOTSTRAP_CSV_SQL_FILE_URLS//,/ }"
  URLS="${URLS//'[DATE]'/$(date -I)}"

  for URL in $URLS; do
    info "Executing $URL"
    curl --fail -s "$URL" -o download.sql || { error "Unable to download the URL $URL"; return 1; }
    if [[ "$URL" == *.sql ]]; then
      psql --set=ON_ERROR_STOP=1 -f download.sql
    elif [[ "$URL" == *.sql.tar.gz ]]; then
      tmpdir=$(mktemp -d)
      tar -xzvf download.sql -C "$tmpdir" || { error "Unable to untar the URL $URL"; return 1; }
      if [[ $DB_BOOTSTRAP_CREATE_DATABASE == "true" ]]; then
        PSQL_DEFAULT_DB="$PGDATABASE"
      else
        PSQL_DEFAULT_DB="postgres"
      fi
      for file in "$tmpdir"/*; do
        psql "$PSQL_DEFAULT_DB" --set=ON_ERROR_STOP=1 -f "$file"
      done
    else
      error "URL extension not supported, error"
    fi
  done
}

info() {
  echo "INFO: $*"
}

error() {
  echo "ERROR: $*"
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

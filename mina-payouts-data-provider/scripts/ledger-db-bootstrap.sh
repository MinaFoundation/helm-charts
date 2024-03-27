#!/usr/bin/env bash
set -e

# Check if environment variables are set
check_env_variable() {
    if [ -z "${!1}" ]; then
        echo "The $1 environment variable is not set or is empty."
        exit 1
    fi
}

# Check required environment variables
check_env_variable "LEDGER_DB_QUERY_USER"
check_env_variable "LEDGER_DB_QUERY_PASSWORD"
check_env_variable "LEDGER_DB_QUERY_HOST"
check_env_variable "LEDGER_DB_QUERY_PORT"
check_env_variable "LEDGER_DB_QUERY_NAME"
check_env_variable "LEDGER_DB_QUERY_SCHEMA_URL"
check_env_variable "LEDGER_DB_QUERY_BOOTSTRAP_DELAY"
check_env_variable "LEDGER_DB_QUERY_REQUIRE_SSL"

PG_CONN=postgres://${LEDGER_DB_QUERY_USER}:${LEDGER_DB_QUERY_PASSWORD}@${LEDGER_DB_QUERY_HOST}:${LEDGER_DB_QUERY_PORT}/${LEDGER_DB_QUERY_NAME}

# Check SSL requirements
if [ "${LEDGER_DB_QUERY_REQUIRE_SSL}" = "true" ]; then
    check_env_variable "LEDGER_DB_QUERY_CERTIFICATE"
    # Dump certificate to a file
    CERTIFICATE_FILE="/tmp/certificate.crt"
    echo "${LEDGER_DB_QUERY_CERTIFICATE}" > "${CERTIFICATE_FILE}"
    # Additional check for certificate content
    if [ ! -s "${CERTIFICATE_FILE}" ]; then
        echo "The LEDGER_DB_QUERY_CERTIFICATE is empty or does not exist."
        exit 1
    fi
    # Include certificate in PG_CONN
    PG_CONN="${PG_CONN}?sslmode=verify-ca&sslrootcert=${CERTIFICATE_FILE}"
fi

# Sleep for the specified delay before proceeding
echo "Sleeping for ${LEDGER_DB_QUERY_BOOTSTRAP_DELAY} seconds..."
sleep "${LEDGER_DB_QUERY_BOOTSTRAP_DELAY}"

# Test the database connection
if ! psql "${PG_CONN}" -c "SELECT 1" >/dev/null 2>&1; then
    echo "Failed to connect to the database using the provided connection string."
    exit 1
fi

# Pull the SQL schema file using curl
SCHEMA_FILE="/tmp/schema.sql"
command -v curl >/dev/null 2>&1 || { apt update && apt install -y curl; }
curl -o "${SCHEMA_FILE}" "${LEDGER_DB_QUERY_SCHEMA_URL}"

# Check if the schema file was downloaded successfully
if [ ! -s "${SCHEMA_FILE}" ]; then
    echo "Failed to download the schema file from ${LEDGER_DB_QUERY_SCHEMA_URL}."
    exit 1
fi

# Run the SQL schema file against the PostgreSQL database
psql "${PG_CONN}" -f "${SCHEMA_FILE}"

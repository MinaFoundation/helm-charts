#!/usr/bin/env bash

set -euo pipefail

echo "INFO: Starting search transaction optimizations script"

apply_search_tx_optimizations() {
    if ! /usr/local/bin/mina-mesh search-tx-optimizations \
        --archive-database-url "$ARCHIVE_DATABASE_URL" \
        --check; then
        echo "INFO: Applying transaction optimizations..."
        /usr/local/bin/mina-mesh search-tx-optimizations \
          --archive-database-url "$ARCHIVE_DATABASE_URL" \
          --apply
    else
        echo "INFO: No optimizations needed."
    fi
}

echo "INFO: Checking for search transaction optimizations"

# Validate SEARCH_TX_OPTIMIZATIONS
case "${SEARCH_TX_OPTIMIZATIONS:-}" in
    "")
        echo "INFO: SEARCH_TX_OPTIMIZATIONS is not set, skipping optimizations."
        exit 0
        ;;
    enabled)
        apply_search_tx_optimizations
        ;;
    disabled)
        echo "INFO: SEARCH_TX_OPTIMIZATIONS is disabled, skipping optimizations."
        exit 0
        ;;
    *)
        echo "ERROR: SEARCH_TX_OPTIMIZATIONS must be 'enabled' or 'disabled'."
        exit 1
        ;;
esac

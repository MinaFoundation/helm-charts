#!/usr/bin/env bash

# Function to check mina client status for liveness
check_liveness() {
  error_code=$(mina client status --json 2>&1 >/dev/null; echo $?)
  if [[ $error_code -ne 0 ]] && [[ $error_code -ne 15 ]]; then
    exit 1
  fi
}

# Function to check mina client status for liveness
check_readiness() {
  sync_status=$(mina client status --json | jq -r 'select(.sync_status) | .sync_status')
  if [ "$sync_status" != "Synced" ]; then
    exit 1
  fi
}

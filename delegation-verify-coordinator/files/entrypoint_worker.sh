#!/usr/bin/env bash

# Source credentials for AWS
source /var/mina-delegation-verify-auth/.env

/go/bin/submission_updater "$START_TIMESTAMP" "$END_TIMESTAMP"

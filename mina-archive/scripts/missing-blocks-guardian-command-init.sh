#!/usr/bin/env bash

set -e

echo "INFO: Guardian init script started"

/scripts/wait-for-db.sh

echo "INFO: Guardian init script complete"

#!/usr/bin/env bash

set -e

echo "INFO: Archive init script started"

/scripts/wait-for-db.sh

if [[ $ARCHIVE_CONFIG_FILE_URL != "" ]]; then
  echo "INFO: Downloading config file $ARCHIVE_CONFIG_FILE_URL"
  curl -s "$ARCHIVE_CONFIG_FILE_URL" > /config/config-file.json
fi

echo "INFO: Archive init script complete"

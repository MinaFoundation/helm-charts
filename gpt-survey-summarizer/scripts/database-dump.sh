#!/usr/bin/env bash

set -e

DATE="$(date +%F_0000)"
FILENAME="$MINA_PLATFORM-gpt-survey-summarizer-dump-$DATE.rdb"

echo "INFO: Installing tools"
apk add aws-cli >/dev/null;

echo "INFO: Exporting dump of database"
redis-cli --pass $REDIS_PASSWORD --rdb $FILENAME

echo "INFO: Creating tar archive"
tar -czvf "$FILENAME.tar.gz" "$FILENAME"

S3_PATH="s3://$S3_BUCKET/$MINA_PLATFORM/$FILENAME.tar.gz"
echo "INFO: Uploading to S3: $S3_PATH"
echo aws s3 cp "$FILENAME.tar.gz" "$S3_PATH" 

echo "INFO: Archive database uploaded to bucket"

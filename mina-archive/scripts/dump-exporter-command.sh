#!/usr/bin/env bash

set -e

DATE="$(date +%F_0000)"
FILENAME="$MINA_NETWORK-archive-dump-$DATE.sql"

echo "INFO: Installing tools"
if command -v aws; then
  echo "AWS cli is already installed"
elif command -v apk; then
  apk add aws-cli > /dev/null
elif command -v apt-get; then
  apt-get update > /dev/null
  apt-get install -y curl unzip > /dev/null
  curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip > /dev/null
  ./aws/install > /dev/null
else
  echo "Unable to install AWS cli"
  exit 1
fi

echo "INFO: Exporting dump of database"
pg_dump --no-owner "$PG_CONN" > "$FILENAME"

echo "INFO: Creating tar archive"
tar -czvf "$FILENAME.tar.gz" "$FILENAME"

S3_PATH="s3://$DUMP_EXPORTER_S3_BUCKET/$MINA_NETWORK/$FILENAME.tar.gz"
echo "INFO: Uploading to S3: $S3_PATH"
aws s3 cp "$FILENAME.tar.gz" "$S3_PATH"

echo "INFO: Archive database exported to bucket"

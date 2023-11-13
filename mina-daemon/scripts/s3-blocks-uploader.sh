#!/usr/bin/env sh

if [ -z "$SOURCE_DIR" ]; then
    echo "The SOURCE_DIR environment variable is not set or is empty."
    exit 1
fi

if [ -z "$S3_BUCKET" ]; then
    echo "The S3_BUCKET environment variable is not set or is empty."
    exit 1
fi

if [ -z "$UPLOAD_INTERVAL" ]; then
    echo "The UPLOAD_INTERVAL environment variable is not set or is empty."
    exit 1
fi

if [ ! -z "$PREFIX" ]; then
    S3_BUCKET="${S3_BUCKET}/${PREFIX}"
    echo "Destination bucket is ${S3_BUCKET}"
fi

cd "$SOURCE_DIR"

while true; do
    # Loop through local files
    echo "Checking for new blocks in $SOURCE_DIR"

    blocks=$(ls | grep json)

    # Check if there are any matching files
    if [ -z "$blocks" ]; then
        echo "No new blocks found in $SOURCE_DIR"
    else
        for local_file in $blocks; do
            # Extract the filename without the path
            block_name=$(basename "${local_file}")

            # Check if the file exists in the S3 bucket
            echo "Check if file ${block_name} exists in s3://${S3_BUCKET}"
            if aws s3 ls "s3://${S3_BUCKET}/${block_name}" 2>&1; then
                echo "=> File ${block_name} already exists in S3. Skipping."
            else
                # Copy the file to S3
                aws s3 cp "${local_file}" "s3://${S3_BUCKET}/${block_name}"
                echo "=> File ${block_name} copied to S3."
            fi
            echo "Remove local block ${block_name}"
            rm -rf "${local_file}"
            echo ""
        done
    fi
    echo "Sleeping for ${UPLOAD_INTERVAL} seconds..."
    sleep $UPLOAD_INTERVAL
done

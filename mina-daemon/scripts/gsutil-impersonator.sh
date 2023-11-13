#!/usr/bin/env bash

# This script is used to impersonate gsutil in the mina-daemon container and store the downloaded blocks in the /blocks directory

FILE_NAME=$(echo $4 | cut -d '/' -f4)
echo "copying block ${FILE_NAME}"
cp -n $3 "/blocks/${FILE_NAME}"

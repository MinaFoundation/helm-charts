#!/usr/bin/env bash

# Source credentials for AWS
source /var/mina-delegation-verify-auth/.env

if [ $NO_CHECKS -eq "1" ]; then
  /bin/delegation-verify cassandra --keyspace $AWS_KEYSPACE "$START_TIMESTAMP" "$END_TIMESTAMP" --no-checks
else
  /bin/delegation-verify cassandra --keyspace $AWS_KEYSPACE "$START_TIMESTAMP" "$END_TIMESTAMP"
fi

#!/bin/bash

set -x

max_retries=10
retries=0

while [ $retries -lt $max_retries ]; do

  invoke create-database

  if [ $? -eq 0 ]; then # create-database was successful
    invoke init-database
    break
  else
    echo "Command invoke create database returned non-zero response"
    exit 1
  fi
  
  ((retries++))

  sleep 6

done

#!/usr/bin/env bash

set -x

pushd ..
invoke create-database
popd || exit

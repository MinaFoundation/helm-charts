#!/usr/bin/env bash

set -x

invoke create-database
invoke init-database
invoke create-ro-user

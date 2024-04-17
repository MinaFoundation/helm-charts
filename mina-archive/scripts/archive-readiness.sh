#!/usr/bin/env bash

# This script checks if the server port is open and listening,
# by any process, without installing additional tooling

# The /proc/*/net/tcp prints the network connections/sockets with hexadecimal values
# The `00000000` is the `0.0.0.0` ip address in hexa format.
# The `%04X` will print the port in hexa format.

grep "$(printf '00000000:%04X' "$ARCHIVE_SERVER_PORT_RPC")" /proc/*/net/tcp

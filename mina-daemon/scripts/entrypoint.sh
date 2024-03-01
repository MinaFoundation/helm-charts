#!/usr/bin/env bash

# Export the MINA_LIBP2P_PASS environment variable if MINA_LIBP2P_PASS_PATH is set
if [ -n "$MINA_LIBP2P_PASS_PATH" ]; then
    if [ -f "$MINA_LIBP2P_PASS_PATH" ]; then
        export MINA_LIBP2P_PASS=$(cat "$MINA_LIBP2P_PASS_PATH")
    fi
fi

# Start the mina daemon
echo "Starting mina daemon with arguments: ${@}"
mina "${@}"

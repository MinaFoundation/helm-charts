#!/usr/bin/env bash
set -e

# Export the MINA_LIBP2P_PASS environment variable if MINA_LIBP2P_PASS_PATH is set
if [ -n "$MINA_LIBP2P_PASS_PATH" ]; then
    if [ -f "$MINA_LIBP2P_PASS_PATH" ]; then
        MINA_LIBP2P_PASS=$(cat "$MINA_LIBP2P_PASS_PATH")
        export MINA_LIBP2P_PASS
    fi
fi

# Set External IP if DISCOVERY_EXTERNAL_IP_ENABLED
if [[ "$DISCOVERY_EXTERNAL_IP_ENABLED" == "true" ]]; then
  retries=2  # Number of retries
  delay=5   # Delay between retries in seconds
  externalIp=""

    until [ -n "$externalIp" ] || [ $retries -eq 0 ]; do
        externalIp=$(dig +short "$DISCOVERY_EXTERNAL_IP_TARGET_DNS" | head -n1)

        if [ -n "$externalIp" ]; then
            break
        else
            echo "Unable to resolve DNS... Retries left: $retries"
            ((retries--))
            sleep $delay
        fi
    done

    if [ -n "$externalIp" ]; then
        echo "Discovered External IP: $externalIp"
    else
        echo "Error: Failed to retrieve external IP after $retries retries."
        exit 1
    fi

    EXTRA_ARGS+="--external-ip $externalIp"
fi;

# Start the mina daemon
echo "Starting mina with arguments:" "$@" "${EXTRA_ARGS}"
exec mina "$@" ${EXTRA_ARGS}

#!/usr/bin/env bash
set -e

retries=2  # Number of retries
delay=5   # Delay between retries in seconds
externalIp=""

until [ -n "$externalIp" ] || [ $retries -eq 0 ]; do
    externalIp=$(nslookup "$DISCOVERY_EXTERNAL_IP_TARGET_DNS" | awk '/^Address: / { print $2; exit }')

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
    echo $externalIp > /data/external-ip
else
    echo "Error: Failed to retrieve external IP after $retries retries."
    exit 1
fi

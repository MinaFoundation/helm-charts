#!/usr/bin/env bash

if [ -z "$MINA_LIBP2P_PRIV_KEYPATH" ]; then
    echo "The MINA_LIBP2P_PRIV_KEYPATH environment variable is not set or is empty."
    exit 1
fi

# Function to generate a random password
generate_password() {
    password=$(openssl rand -base64 64 | tr -dc 'a-zA-Z0-9' | head -c 64)
    echo "$password"
}

generate_libp2p_keys() {
    mina libp2p generate-keypair -privkey-path ${MINA_LIBP2P_PRIV_KEYPATH}
    chmod -R 0700 "$(dirname ${MINA_LIBP2P_PRIV_KEYPATH})"
    chmod -R 0600 ${MINA_LIBP2P_PRIV_KEYPATH}*
}

# Generate the libp2p keypair password
export MINA_LIBP2P_PASS=$(generate_password)

# Write the password to disk
echo "${MINA_LIBP2P_PASS}" > "${MINA_LIBP2P_PRIV_KEYPATH}.password"

# Generate the libp2p keypair
generate_libp2p_keys $MINA_LIBP2P_PRIV_KEYPATH

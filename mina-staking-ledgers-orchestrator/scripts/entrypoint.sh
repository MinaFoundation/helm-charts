#!/usr/bin/env bash
set -e

# Check if python3 is installed
if ! command -v python3 &> /dev/null; then
    echo "Python3 is not installed. Please install it."
    exit 1
fi

# Check if pip3 is installed
if ! command -v pip3 &> /dev/null; then
    echo "pip3 is not installed. Installing pip3..."
    sudo apt update
    sudo apt install -y python3-pip
fi

# Install dependencies from requirements.txt
echo "Installing dependencies from requirements.txt..."
pip3 install -r /scripts/requirements.txt

# Run the Python script
echo "Running mina-staking-ledgers-orchestrator.py..."
python3 /scripts/mina-staking-ledgers-orchestrator.py

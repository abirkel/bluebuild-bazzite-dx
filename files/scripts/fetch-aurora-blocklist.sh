#!/usr/bin/env bash

set -oue pipefail

echo "========================================" >&2
echo "SCRIPT STARTING: fetch-aurora-blocklist.sh" >&2
echo "PWD: $(pwd)" >&2
echo "USER: $(whoami)" >&2
echo "========================================" >&2

echo "Fetching Aurora blocklist..."

# Create directory if it doesn't exist
mkdir -p /etc/bazaar

# Download the latest blocklist from Aurora
curl -fsSL https://raw.githubusercontent.com/get-aurora-dev/common/main/system_files/shared/etc/bazaar/blocklist.yaml \
    -o /etc/bazaar/blocklist.yaml

echo "Aurora blocklist installed successfully"

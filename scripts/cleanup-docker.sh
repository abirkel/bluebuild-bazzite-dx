#!/usr/bin/env bash
set -euo pipefail

# Remove Docker CE repository (no longer needed)
rm -f /etc/yum.repos.d/docker-ce.repo

# Remove Docker-specific kernel module configuration
# This loads iptable_nat for docker-in-docker support
# See: https://github.com/ublue-os/bluefin/issues/2365
rm -f /etc/modules-load.d/ip_tables.conf

# Remove docker group from /etc/group
# Note: We keep the 20-dx.sh file as it may be used for other groups in the future (e.g., incus-admin)
if grep -q "^docker:" /etc/group; then
    sed -i '/^docker:/d' /etc/group
fi

# Remove users from docker group (cleanup /etc/group entries)
# This removes docker from supplementary groups for all users
sed -i 's/,docker//g; s/:docker,/:/g; s/:docker$/:/g' /etc/group

echo "Docker cleanup complete."

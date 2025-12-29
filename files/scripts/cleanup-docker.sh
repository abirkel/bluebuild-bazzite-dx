#!/usr/bin/env bash
set -oue pipefail

echo "========================================" >&2
echo "SCRIPT STARTING: cleanup-docker.sh" >&2
echo "========================================" >&2

# Remove Docker CE repository (no longer needed)
rm -f /etc/yum.repos.d/docker-ce.repo

# Keep ip_tables.conf - iptable_nat module is needed for network auto-connect on first boot
# Originally added for docker-in-docker support, but appears to be required for NetworkManager
# See: https://github.com/ublue-os/bluefin/issues/2365
# rm -f /etc/modules-load.d/ip_tables.conf

# Remove docker group from /etc/group
# Note: We keep the 20-dx.sh file as it may be used for other groups in the future (e.g., incus-admin)
if grep -q "^docker:" /etc/group 2>/dev/null; then
    echo "Removing docker group from /etc/group..." >&2
    sed -i '/^docker:/d' /etc/group
else
    echo "No docker group found in /etc/group" >&2
fi

# Remove users from docker group (cleanup /etc/group entries)
# This removes docker from supplementary groups for all users
echo "Cleaning up docker from supplementary groups..." >&2
sed -i 's/,docker//g; s/:docker,/:/g; s/:docker$/:/g' /etc/group

echo "Docker cleanup complete."

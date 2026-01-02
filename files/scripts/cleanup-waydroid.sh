#!/usr/bin/env bash
set -euo pipefail

# Remove Waydroid desktop entries and related files
rm -f /usr/share/applications/waydroid.*.desktop
rm -f /usr/share/applications/Waydroid.desktop
rm -f /usr/share/applications/waydroid-container-restart.desktop

# Remove Waydroid configuration directories if they exist
rm -rf /etc/waydroid 2>/dev/null || true

echo "Waydroid cleanup complete."

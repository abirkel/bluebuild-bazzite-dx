#!/usr/bin/env bash
# Disable BlueBuild's flatpak auto-install after first run
# This allows users to freely uninstall flatpaks without them being reinstalled

set -euo pipefail

VERSION_FILE="/etc/ublue-os/.flatpak-oneshot-done"

# Skip if already done
if [[ -f "$VERSION_FILE" ]]; then
    echo "Flatpak auto-install already disabled. Skipping."
    exit 0
fi

echo "Disabling BlueBuild flatpak auto-install using bluebuild-flatpak-manager..."

# Use the official BlueBuild tool to disable automatic flatpak installation
bluebuild-flatpak-manager disable all

# Mark as done
mkdir -p "$(dirname "$VERSION_FILE")"
echo "1" > "$VERSION_FILE"

echo "Flatpak auto-install disabled. Users can now freely manage flatpaks."
echo "To re-enable: bluebuild-flatpak-manager enable all"

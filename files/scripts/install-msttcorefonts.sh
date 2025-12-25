#!/usr/bin/env bash

# Tell this script to exit if there are any errors.
set -oue pipefail

echo "Installing Microsoft TrueType Core Fonts..."

# Create fonts directory
FONT_DIR="/usr/share/fonts/msttcorefonts"
mkdir -p "${FONT_DIR}"

# Temporary directory for downloads
TEMP_DIR=$(mktemp -d)
cd "${TEMP_DIR}"

# Font URLs from SourceForge (official mirror for the original installers)
declare -A FONTS=(
    ["andale32.exe"]="https://downloads.sourceforge.net/corefonts/andale32.exe"
    ["arial32.exe"]="https://downloads.sourceforge.net/corefonts/arial32.exe"
    ["arialb32.exe"]="https://downloads.sourceforge.net/corefonts/arialb32.exe"
    ["comic32.exe"]="https://downloads.sourceforge.net/corefonts/comic32.exe"
    ["courie32.exe"]="https://downloads.sourceforge.net/corefonts/courie32.exe"
    ["georgi32.exe"]="https://downloads.sourceforge.net/corefonts/georgi32.exe"
    ["impact32.exe"]="https://downloads.sourceforge.net/corefonts/impact32.exe"
    ["times32.exe"]="https://downloads.sourceforge.net/corefonts/times32.exe"
    ["trebuc32.exe"]="https://downloads.sourceforge.net/corefonts/trebuc32.exe"
    ["verdan32.exe"]="https://downloads.sourceforge.net/corefonts/verdan32.exe"
    ["webdin32.exe"]="https://downloads.sourceforge.net/corefonts/webdin32.exe"
)

# Download and extract each font package using 7z
for exe in "${!FONTS[@]}"; do
    url="${FONTS[$exe]}"
    echo "Downloading ${exe}..."
    
    if curl -L -f -o "${exe}" "${url}"; then
        echo "Extracting ${exe}..."
        7z e "${exe}" "*.ttf" "*.TTF" -o"${FONT_DIR}" -y > /dev/null
    else
        echo "Warning: Failed to download ${exe}, skipping..."
    fi
done

# Set proper permissions
chmod 644 "${FONT_DIR}"/*.{ttf,TTF} 2>/dev/null || true

# Update font cache
echo "Updating font cache..."
fc-cache -f "${FONT_DIR}"

# Cleanup
cd /
rm -rf "${TEMP_DIR}"

echo "Microsoft TrueType Core Fonts installation complete!"
echo "Installed fonts:"
ls -1 "${FONT_DIR}"

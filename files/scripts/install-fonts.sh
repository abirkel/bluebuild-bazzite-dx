#!/usr/bin/env bash

# Tell this script to exit if there are any errors.
set -oue pipefail

echo "Installing fonts..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FONTS_ARCHIVE="${SCRIPT_DIR}/fonts.7z"

# Check if fonts archive exists
if [ ! -f "${FONTS_ARCHIVE}" ]; then
    echo "Error: fonts.7z not found at ${FONTS_ARCHIVE}"
    exit 1
fi

# Create temporary extraction directory
TEMP_DIR=$(mktemp -d)
cd "${TEMP_DIR}"

# Extract the archive
echo "Extracting fonts archive..."
7z x "${FONTS_ARCHIVE}" -y > /dev/null

# Install mscore fonts
if [ -d "mscore" ]; then
    echo "Installing MS Core fonts..."
    MSCORE_DIR="/usr/share/fonts/mscore"
    mkdir -p "${MSCORE_DIR}"
    cp mscore/*.{ttf,ttc,TTF,TTC} "${MSCORE_DIR}/" 2>/dev/null || true
    chmod 644 "${MSCORE_DIR}"/* 2>/dev/null || true
    echo "MS Core fonts installed to ${MSCORE_DIR}"
fi

# Install additional fonts
if [ -d "additional" ]; then
    echo "Installing additional fonts..."
    ADDITIONAL_DIR="/usr/share/fonts/additional"
    mkdir -p "${ADDITIONAL_DIR}"
    cp additional/*.{ttf,ttc,TTF,TTC} "${ADDITIONAL_DIR}/" 2>/dev/null || true
    chmod 644 "${ADDITIONAL_DIR}"/* 2>/dev/null || true
    echo "Additional fonts installed to ${ADDITIONAL_DIR}"
fi

# Update font cache
echo "Updating font cache..."
fc-cache -f

# Cleanup
cd /
rm -rf "${TEMP_DIR}"

echo "Font installation complete!"
echo ""
echo "Installed fonts:"
[ -d "/usr/share/fonts/mscore" ] && echo "MS Core fonts:" && ls -1 /usr/share/fonts/mscore | column
[ -d "/usr/share/fonts/additional" ] && echo "Additional fonts:" && ls -1 /usr/share/fonts/additional | column

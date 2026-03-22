#!/usr/bin/env zsh
#
# Usage: ./gh-install.sh <download_url> <expected_sha256> <binary_name> [install_dir]
#
# Downloads a release asset from GitHub, verifies its SHA-256 checksum,
# extracts the binary, and installs it.
#
# Supports .zip and .tar.gz/.tgz archives, or raw binaries.
#
# Examples:
#   ./gh-install.sh \
#     "https://github.com/bitwarden/clients/releases/download/cli-v2026.2.0/bw-macos-arm64-2026.2.0.zip" \
#     "63c736b74620280e422ce238bdbcbc267689a0ff831168959ef2124588fcc1e5" \
#     bw
#
#   ./gh-install.sh \
#     "https://github.com/gitleaks/gitleaks/releases/download/v8.16.4/gitleaks_8.16.4_darwin_x64.tar.gz" \
#     "4ac90876951f79341a76c61e847394c25895a5c5bbf316453757f7b48651b869" \
#     gitleaks
#
set -e

if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <download_url> <expected_sha256> <binary_name> [install_dir]"
    exit 1
fi

DOWNLOAD_URL="$1"
EXPECTED_SHA256="$2"
BINARY_NAME="$3"
INSTALL_DIR="${4:-/usr/local/bin}"

FILENAME="${DOWNLOAD_URL##*/}"

echo "Downloading $BINARY_NAME from $DOWNLOAD_URL..."
curl -o "$FILENAME" -fsSL "$DOWNLOAD_URL"

echo "Verifying checksum..."
ACTUAL_SHA256=$(shasum -a 256 "$FILENAME" | awk '{print $1}')
if [[ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]]; then
    echo "Checksum verification FAILED."
    echo "  Expected: $EXPECTED_SHA256"
    echo "  Got:      $ACTUAL_SHA256"
    rm "$FILENAME"
    exit 1
fi
echo "Checksum verified."

if [[ "$FILENAME" == *.tar.gz || "$FILENAME" == *.tgz ]]; then
    tar --no-same-owner -zxf "$FILENAME" "$BINARY_NAME"
    rm "$FILENAME"
elif [[ "$FILENAME" == *.zip ]]; then
    unzip -o "$FILENAME" "$BINARY_NAME"
    rm "$FILENAME"
else
    mv "$FILENAME" "$BINARY_NAME"
fi

chmod +x "$BINARY_NAME"

if [ -w "$INSTALL_DIR" ]; then
    mv "$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"
    echo "Installed $BINARY_NAME to $INSTALL_DIR/$BINARY_NAME"
else
    echo "Cannot write to $INSTALL_DIR. Move '$BINARY_NAME' to a directory in your PATH manually."
fi

#!/bin/bash
#
# DoIt installer — downloads the latest release from GitHub and drops
# it into /Applications. Strips the quarantine flag so Gatekeeper
# doesn't block the ad-hoc signed build.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/duncanlowrie/DoIt/main/install.sh | bash
#

set -euo pipefail

REPO="duncanlowrie/DoIt"
APP_NAME="DoIt.app"
INSTALL_DIR="/Applications"
URL="https://github.com/$REPO/releases/latest/download/DoIt.zip"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "==> Downloading latest DoIt release"
curl -fsSL "$URL" -o "$TMP/DoIt.zip"

echo "==> Unpacking"
ditto -x -k "$TMP/DoIt.zip" "$TMP"

if [ ! -d "$TMP/$APP_NAME" ]; then
    echo "Unexpected archive contents: no $APP_NAME found" >&2
    exit 1
fi

echo "==> Installing to $INSTALL_DIR"
if [ -d "$INSTALL_DIR/$APP_NAME" ]; then
    # If the running instance holds onto the old bundle, ask it to quit.
    osascript -e 'tell application "DoIt" to quit' 2>/dev/null || true
    rm -rf "$INSTALL_DIR/$APP_NAME"
fi
mv "$TMP/$APP_NAME" "$INSTALL_DIR/"

echo "==> Removing quarantine flag"
xattr -dr com.apple.quarantine "$INSTALL_DIR/$APP_NAME" 2>/dev/null || true

echo ""
echo "DoIt installed at $INSTALL_DIR/$APP_NAME"
echo "Launching..."
open "$INSTALL_DIR/$APP_NAME"

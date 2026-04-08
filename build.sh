#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

if [ ! -f Resources/AppIcon.icns ]; then
    echo "==> Generating app icon (Resources/AppIcon.icns not found)"
    ./scripts/make_icon.sh
fi

echo "==> Building release binary"
swift build -c release --arch arm64

APP="DoIt.app"
BIN=".build/arm64-apple-macosx/release/DoIt"

echo "==> Assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp "$BIN" "$APP/Contents/MacOS/DoIt"
cp Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

# Ad-hoc sign so macOS lets it run.
codesign --force --deep --sign - "$APP" >/dev/null

echo ""
echo "Built: $(pwd)/$APP"
echo ""
echo "Run it:      open $APP"
echo "Install it:  mv $APP /Applications/"
echo ""
echo "To launch at login: System Settings → General → Login Items → +"

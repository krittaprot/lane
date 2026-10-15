#!/bin/bash
# Builds build/Lane.app as a universal (Apple Silicon + Intel) app. Run from anywhere; paths are relative to the project root.
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release --arch arm64 --arch x86_64
BIN="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/Lane"

APP=build/Lane.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Lane"
cp Resources/Info.plist "$APP/Contents/Info.plist"

if [[ ! -f build/AppIcon.icns ]]; then
  ICONSET=build/AppIcon.iconset
  mkdir -p "$ICONSET"
  swift scripts/make-icon.swift build/icon-1024.png
  for px in 16 32 128 256 512; do
    sips -z $px $px build/icon-1024.png --out "$ICONSET/icon_${px}x${px}.png" >/dev/null
    sips -z $((px * 2)) $((px * 2)) build/icon-1024.png --out "$ICONSET/icon_${px}x${px}@2x.png" >/dev/null
  done
  iconutil -c icns "$ICONSET" -o build/AppIcon.icns
fi
cp build/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

codesign --force --sign - "$APP"
echo "Built $APP"

#!/bin/bash
# Builds build/Lane-<version>.dmg: the universal app plus an Applications shortcut to drag it onto.
set -euo pipefail
cd "$(dirname "$0")/.."

scripts/build.sh

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Resources/Info.plist)
DMG="build/Lane-$VERSION.dmg"
STAGING=build/dmg

rm -rf "$STAGING" "$DMG"
mkdir -p "$STAGING"
cp -R build/Lane.app "$STAGING/Lane.app"
ln -s /Applications "$STAGING/Applications"

hdiutil create -volname "Lane $VERSION" -srcfolder "$STAGING" -format UDZO -ov "$DMG" >/dev/null
rm -rf "$STAGING"

shasum -a 256 "$DMG"
echo "Built $DMG"

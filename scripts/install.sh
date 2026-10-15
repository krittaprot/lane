#!/bin/bash
# Builds Lane and installs it to ~/Applications, quitting any running copy first.
set -euo pipefail
cd "$(dirname "$0")/.."

scripts/build.sh
pkill -x Lane || true
mkdir -p ~/Applications
rm -rf ~/Applications/Lane.app
cp -R build/Lane.app ~/Applications/Lane.app
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f ~/Applications/Lane.app
open ~/Applications/Lane.app
echo "Installed ~/Applications/Lane.app"

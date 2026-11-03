#!/bin/zsh
# Builds a Release and packages it as dist/KEXP-Now-Playing-<version>.dmg for a GitHub release.
# Version comes from MARKETING_VERSION in project.yml.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=$(sed -nE 's/^ *MARKETING_VERSION: *"?([^"]+)"?/\1/p' project.yml | head -1)
NAME="KEXP Now Playing"
APP="build/Build/Products/Release/$NAME.app"
DMG="dist/KEXP-Now-Playing-$VERSION.dmg"

CONFIG=Release ./scripts/build.sh --no-install

STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
ditto "$APP" "$STAGE/$NAME.app"
ln -s /Applications "$STAGE/Applications"

mkdir -p dist
rm -f "$DMG"
hdiutil create -quiet -volname "$NAME" -srcfolder "$STAGE" -format UDZO -ov "$DMG"

echo "Packaged $DMG"
echo "Release it: gh release create v$VERSION \"$DMG\" --title \"v$VERSION\" --generate-notes"

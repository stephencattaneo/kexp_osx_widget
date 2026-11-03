#!/bin/zsh
# Builds KEXP Now Playing without an Apple developer team: compiles unsigned,
# then ad-hoc signs the widget extension and app with their entitlements, and
# installs to ~/Applications so WidgetKit can discover the widget.
# Usage: build.sh [--open | --no-install]
set -euo pipefail
cd "$(dirname "$0")/.."

command -v xcodegen >/dev/null || { echo "Install XcodeGen: brew install xcodegen"; exit 1; }
xcodegen generate --quiet

CONFIG="${CONFIG:-Release}"
xcodebuild -project KEXPNowPlaying.xcodeproj -scheme KEXPNowPlaying \
  -configuration "$CONFIG" -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO build -quiet

APP="build/Build/Products/$CONFIG/KEXP Now Playing.app"
APPEX="$APP/Contents/PlugIns/KEXPWidget.appex"

codesign --force --sign - --entitlements Widget/KEXPWidget.entitlements --generate-entitlement-der "$APPEX"
codesign --force --sign - --entitlements App/KEXPNowPlaying.entitlements --generate-entitlement-der "$APP"
codesign --verify --deep --strict "$APP"

[[ "${1:-}" == "--no-install" ]] && { echo "Built $APP"; exit 0; }

DEST="$HOME/Applications/KEXP Now Playing.app"
OLD="$HOME/Applications/KEXPNowPlaying.app"   # pre-rename install
mkdir -p "$HOME/Applications"
pkill -x "KEXP Now Playing" 2>/dev/null || true
pkill -x KEXPNowPlaying 2>/dev/null || true
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
if [[ -d "$OLD" ]]; then "$LSREGISTER" -u "$OLD" 2>/dev/null || true; rm -rf "$OLD"; fi
rm -rf "$DEST"
cp -R "$APP" "$DEST"
"$LSREGISTER" -f "$DEST"
pluginkit -a "$DEST/Contents/PlugIns/KEXPWidget.appex" 2>/dev/null || true

echo "Installed $DEST"
[[ "${1:-}" == "--open" ]] && open "$DEST"
exit 0

#!/bin/zsh
# Builds KEXP Now Playing without an Apple developer team: compiles unsigned,
# then ad-hoc signs the widget extension and app with their entitlements, and
# installs to /Applications so WidgetKit can discover the widget.
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

DEST="/Applications/KEXP Now Playing.app"
# Earlier source builds installed to ~/Applications; remove them so WidgetKit
# doesn't pick up a stale copy of the widget.
OLD=("$HOME/Applications/KEXP Now Playing.app" "$HOME/Applications/KEXPNowPlaying.app")
pkill -x "KEXP Now Playing" 2>/dev/null || true
pkill -x KEXPNowPlaying 2>/dev/null || true
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
for old in "${OLD[@]}"; do
  if [[ -d "$old" ]]; then "$LSREGISTER" -u "$old" 2>/dev/null || true; rm -rf "$old"; fi
done
# Build products (any configuration) get registered by Xcode/Spotlight too; unregister
# them so the widget only ever loads from $DEST.
for product in build/Build/Products/*/"KEXP Now Playing.app"(N); do
  pluginkit -r "$product/Contents/PlugIns/KEXPWidget.appex" 2>/dev/null || true
  "$LSREGISTER" -u "$product" 2>/dev/null || true
done
rm -rf "$DEST"
cp -R "$APP" "$DEST"
"$LSREGISTER" -f "$DEST"
pluginkit -a "$DEST/Contents/PlugIns/KEXPWidget.appex" 2>/dev/null || true
# chronod (the widget renderer) keeps serving views rendered by the old build, links and
# all, even after the extension is replaced. Restarting it (launchd relaunches it) forces
# a fresh render.
killall chronod 2>/dev/null || true

echo "Installed $DEST"
[[ "${1:-}" == "--open" ]] && open "$DEST"
exit 0

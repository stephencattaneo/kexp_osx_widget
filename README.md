# KEXP Now Playing

![KEXP Now Playing widgets: small, medium and large](docs/widgets.png)

macOS widget + background player for KEXP 90.3 FM, with Now Playing / media-key support. Requires macOS 15+.

## Install

1. Download the latest `.dmg` from [Releases](https://github.com/stephencattaneo/kexp_osx_widget/releases/latest).
2. Open it and drag **KEXP Now Playing** to **Applications**.
3. Open the app. macOS will block it (unverified developer) → **System Settings › Privacy & Security** → **Open Anyway**.
   1. This is required because I don't have a paid Apple Developer account.
5. Right-click the desktop → **Edit Widgets…** → search **KEXP**.

The app runs in the background (no Dock or menu-bar icon) and handles playback and live track updates.
Play/pause from the widget, macOS Now Playing, or media keys. Quit: `open kexpnowplaying://quit`.

### Or build from source

Needs Xcode 26+.

```sh
brew install xcodegen
rake install   # builds, installs to /Applications, and launches
```

## Uninstall

macOS won't trash the app while it's running, so quit it first:

1. Remove the KEXP widget from your desktop (right-click it → **Remove Widget**).
2. Quit the app: `open kexpnowplaying://quit` (or `pkill -x "KEXP Now Playing"`, or Activity Monitor → search "KEXP" → Quit).
3. Drag **KEXP Now Playing** from **Applications** to the Trash.

## Releasing (maintainer)

1. Bump `MARKETING_VERSION` in `project.yml`, commit, push.
2. `rake release`: builds `dist/KEXP-Now-Playing-<version>.dmg` and publishes it as GitHub release `v<version>` (stops early if the working tree is dirty, the commit isn't pushed, or the release already exists). Use `rake package` to build the DMG without publishing.

Release when user-facing behavior changes; no need for README/script-only changes.

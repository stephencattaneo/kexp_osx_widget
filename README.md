# KEXP Now Playing for macOS

Desktop / Notification Center widget (small, medium, large; light & dark) showing what's on
KEXP 90.3 FM, plus a menu-bar app that plays the live stream. Design:
<https://claude.ai/artifact/4VjRbTDnvo6tt8gfyfoxZf>

## Build & install

Requires Xcode 26+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```sh
./scripts/build.sh --open
```

This builds, ad-hoc signs (no Apple developer team needed), installs to
`~/Applications/KEXP Now Playing.app`, and launches it. Then right-click the desktop →
**Edit Widgets…** → search "KEXP".

To work in Xcode instead: `xcodegen generate && open KEXPNowPlaying.xcodeproj`.

The app icon is generated: `swift scripts/make-icon.swift App/Assets.xcassets/AppIcon.appiconset`.

## Layout

| Path | What |
|---|---|
| `Shared/KEXPClient.swift` | `api.kexp.org/v2` plays + show lookup, artwork prefetch |
| `Shared/NowPlayingViews.swift` | Small / Medium / Large layouts from the design |
| `Shared/Theme.swift`, `Components.swift` | Palette, KEXP mark, live badge, play button |
| `Shared/SharedState.swift` | Play state + the `kexpnowplaying://toggle` URL behind the widget's play button |
| `App/` | Menu-bar app: `RadioPlayer` (AVPlayer on the AAC stream), API polling every 30 s |
| `Widget/` | WidgetKit extension; timeline refreshes every 90 s |

Play state lives in the app's preferences, which the widget reads through a read-only sandbox
exception (App Groups and App Intents both need a signing team ID). The app
reloads widget timelines on every track change and play/pause, so keep it running for
up-to-the-song accuracy; on its own, the widget refreshes on WidgetKit's budget.

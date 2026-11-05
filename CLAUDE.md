# KEXP Now Playing

macOS desktop widget (WidgetKit extension) plus a background host app (no Dock or menu-bar icon) that plays the KEXP stream and polls `api.kexp.org`. `App/` is the host, `Widget/` the extension, and `Shared/` is compiled into both; `#if WIDGET_EXTENSION` marks widget-only code.

## Workflow

- Run tasks with `rake -T`: `build`, `install`, `package`, `release`. `project.yml` (XcodeGen) is the source of truth: `KEXPNowPlaying.xcodeproj` is regenerated on every build and gitignored, so make project changes in `project.yml`.
- **Verify in the real widget:** run `rake install`, which installs to `/Applications`, restarts `chronod` and relaunches the app. There are no tests. You can't click the widget yourself, so ask the user to click and read the app log to see what arrived:
  ```sh
  /usr/bin/log show --last 5m --style compact --info --predicate 'subsystem == "us.dotnetorgcom.KEXPNowPlaying"'
  ```
  Write the full path `/usr/bin/log`, because zsh's built-in `log` shadows it and silently returns nothing. Every URL the app receives is logged under category `URL`.
- **Release:** commit the changes, then run `rake release`. It bumps the version in `project.yml`, builds the DMG, commits, tags, pushes and publishes the GitHub release, with no prompts; preflight checks abort on bad state. Release when user-facing behavior changes.

## Gotchas

- **Widget clicks go to the host app.** macOS hands every widget `Link`/`widgetURL` to the containing app instead of opening it. Web links from the widget must use `kexpnowplaying://<action>` URLs (built with `SharedState.widgetLink`), and `AppDelegate.handleGetURL` opens the page with `NSWorkspace`. To add a link, add a case there. A plain `https://` link in the widget does nothing.
- Any widget click activates the app, which hides the desktop widgets. That's macOS behavior, not a bug to chase.
- **Stale widget views:** `chronod` keeps serving views (links included) rendered by an old build, even after reinstalls and timeline reloads. If the widget acts like old code, run `killall chronod`.
- **One installed copy.** If an extra copy exists (an old `~/Applications` build or a DMG install), WidgetKit may load its widget instead. `scripts/build.sh` removes the `~/Applications` copies.
- **No signing team:** builds are ad-hoc signed. That's why app↔widget state uses the host's standard defaults plus the widget's `shared-preference.read-only` entitlement instead of App Groups (see `Shared/SharedState.swift`).
- Widgets can't load remote images at render time, so artwork bytes are fetched up front into `TrackInfo.artwork`.
- `api.kexp.org/v2` has no web URLs. Show pages are built from the show ID as `https://www.kexp.org/playlist/show/<id>/`. Program pages (`/shows/<slug>/`) can't be built reliably from the show name.

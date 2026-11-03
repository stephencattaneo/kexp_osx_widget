import Foundation

/// State shared between the host app and the widget extension.
///
/// The app writes to its own standard defaults
/// (`~/Library/Preferences/com.scattaneo.KEXPNowPlaying.plist`); the sandboxed widget reads
/// that domain via a `shared-preference.read-only` entitlement. This avoids App Groups, which
/// require a signing team ID.
enum SharedState {
    static let appDomain = "com.scattaneo.KEXPNowPlaying"
    static let widgetKind = "KEXPNowPlayingWidget"

    /// Opening this URL launches the app (if needed) and toggles playback.
    static let toggleURL = URL(string: "kexpnowplaying://toggle")!

    private static let isPlayingKey = "isPlaying"

    private static var defaults: UserDefaults {
        #if WIDGET_EXTENSION
        UserDefaults(suiteName: appDomain) ?? .standard
        #else
        .standard
        #endif
    }

    static var isPlaying: Bool {
        get { defaults.bool(forKey: isPlayingKey) }
        set { defaults.set(newValue, forKey: isPlayingKey) }
    }
}

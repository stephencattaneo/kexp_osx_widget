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

    /// macOS hands widget link URLs to the host app rather than opening them, so web links
    /// from the widget go through the app, which opens the page in the default browser.
    static let playlistURL = URL(string: "kexpnowplaying://playlist")!
    static let homeURL = URL(string: "kexpnowplaying://home")!
    static func showURL(id: Int) -> URL { URL(string: "kexpnowplaying://show/\(id)")! }

    /// The URL a widget `Link` should use to reach `webURL`.
    static func widgetLink(_ appURL: URL, web webURL: URL) -> URL {
        #if WIDGET_EXTENSION
        appURL
        #else
        webURL
        #endif
    }

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

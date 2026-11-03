import SwiftUI

/// Handles `kexpnowplaying://toggle` from the widget's play button. Registered as an
/// Apple Event handler so it works whether or not the menu-bar window is open, and on
/// cold launch.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURL(_:withReply:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @objc private func handleGetURL(_ event: NSAppleEventDescriptor, withReply reply: NSAppleEventDescriptor) {
        guard let string = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: string), url.scheme == SharedState.toggleURL.scheme else { return }
        MainActor.assumeIsolated {
            switch url.host() {
            case "toggle": RadioPlayer.shared.toggle()
            case "play": RadioPlayer.shared.play()
            case "pause": RadioPlayer.shared.pause()
            default: break
            }
        }
    }
}

@main
struct KEXPNowPlayingApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = NowPlayingModel()
    private let player = RadioPlayer.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent(model: model, player: player)
        } label: {
            Image(systemName: player.isPlaying ? "radio.fill" : "radio")
                .accessibilityLabel("KEXP Now Playing")
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuBarContent: View {
    var model: NowPlayingModel
    var player: RadioPlayer
    @Environment(\.colorScheme) private var scheme
    @Environment(\.openURL) private var openURL

    var body: some View {
        let theme = KEXPTheme.of(scheme)
        VStack(spacing: 0) {
            LargeNowPlayingView(data: model.data ?? .placeholder, playing: player.isPlaying)
                .redacted(reason: model.data == nil ? .placeholder : [])
                .frame(width: 364, height: 382)
                .environment(\.kexpTheme, theme)

            if let error = player.lastError ?? model.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(theme.liveText)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }

            HStack {
                Button("Open KEXP Playlist") { openURL(KEXP.websiteURL) }
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .keyboardShortcut("q")
            }
            .buttonStyle(.link)
            .font(.system(size: 12))
            .tint(theme.accent)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .overlay(alignment: .top) { Rectangle().fill(theme.divider).frame(height: 1) }
        }
        .background(theme.background)
    }
}

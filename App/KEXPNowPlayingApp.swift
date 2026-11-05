import SwiftUI
import os

/// Background agent (no Dock or menu-bar icon). Controlled from the widget, macOS Now Playing,
/// media keys, and `kexpnowplaying://` URLs.
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Polls KEXP and pushes track changes to the widget and Now Playing.
    private var model: NowPlayingModel?

    func applicationWillFinishLaunching(_ notification: Notification) {
        // Registered as an Apple Event handler so URLs work on cold launch too.
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURL(_:withReply:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        MainActor.assumeIsolated { model = NowPlayingModel() }
    }

    /// `kexpnowplaying://toggle | play | pause | quit | restart | playlist | home | show/<id>`
    @objc private func handleGetURL(_ event: NSAppleEventDescriptor, withReply reply: NSAppleEventDescriptor) {
        let string = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue
        Logger(subsystem: SharedState.appDomain, category: "URL").info("open \(string ?? "<nil>", privacy: .public)")
        guard let string, let url = URL(string: string), url.scheme == SharedState.toggleURL.scheme else { return }
        MainActor.assumeIsolated {
            switch url.host() {
            case "toggle": RadioPlayer.shared.toggle()
            case "play": RadioPlayer.shared.play()
            case "pause": RadioPlayer.shared.pause()
            case "playlist": NSWorkspace.shared.open(KEXP.websiteURL)
            case "home": NSWorkspace.shared.open(KEXP.homeURL)
            case "show":
                if let id = Int(url.lastPathComponent) { NSWorkspace.shared.open(KEXP.showURL(id: id)) }
            case "quit":
                RadioPlayer.shared.pause()
                NSApplication.shared.terminate(nil)
            case "restart":
                Self.relaunch(resumePlaying: RadioPlayer.shared.isPlaying)
            default: break
            }
        }
    }

    /// Quits and starts a fresh copy, resuming the stream if it was playing. A detached shell
    /// waits for this process to exit before reopening the bundle.
    @MainActor private static func relaunch(resumePlaying: Bool) {
        let shell = Process()
        shell.executableURL = URL(fileURLWithPath: "/bin/sh")
        shell.arguments = [
            "-c",
            #"while kill -0 "$1" 2>/dev/null; do sleep 0.2; done; /usr/bin/open -g -a "$2" ${3:+"$3"}"#,
            "relaunch",
            String(ProcessInfo.processInfo.processIdentifier),
            Bundle.main.bundlePath,
            resumePlaying ? "kexpnowplaying://play" : "",
        ]
        do {
            try shell.run()
        } catch {
            Logger(subsystem: SharedState.appDomain, category: "URL").error("relaunch failed: \(error, privacy: .public)")
            return
        }
        RadioPlayer.shared.pause()
        NSApplication.shared.terminate(nil)
    }
}

@main
struct KEXPNowPlayingApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // SwiftUI needs a scene; a Settings scene with no content shows nothing.
        Settings { EmptyView() }
    }
}

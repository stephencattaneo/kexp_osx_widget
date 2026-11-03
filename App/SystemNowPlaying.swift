import AppKit
import MediaPlayer

/// Publishes KEXP to the system's Now Playing (Control Center / menu bar media widget) and
/// handles media keys, AirPods and Control Center play/pause.
///
/// Nothing is published until the user first presses play, so the app doesn't take the
/// Now Playing slot from other apps just by running.
@MainActor
final class SystemNowPlaying {
    static let shared = SystemNowPlaying()

    private let center = MPNowPlayingInfoCenter.default()
    private var hasPlayed = false
    private var data: NowPlaying?
    private var isPlaying = false

    private init() {
        let commands = MPRemoteCommandCenter.shared()
        commands.playCommand.addTarget { _ in
            Task { @MainActor in RadioPlayer.shared.play() }
            return .success
        }
        commands.pauseCommand.addTarget { _ in
            Task { @MainActor in RadioPlayer.shared.pause() }
            return .success
        }
        commands.togglePlayPauseCommand.addTarget { _ in
            Task { @MainActor in RadioPlayer.shared.toggle() }
            return .success
        }
        // A live stream can't skip or seek.
        for command in [commands.nextTrackCommand, commands.previousTrackCommand,
                        commands.skipForwardCommand, commands.skipBackwardCommand,
                        commands.seekForwardCommand, commands.seekBackwardCommand,
                        commands.changePlaybackPositionCommand] as [MPRemoteCommand] {
            command.isEnabled = false
        }
    }

    /// Call whenever playback starts or stops.
    func setPlaying(_ playing: Bool) {
        isPlaying = playing
        if playing { hasPlayed = true }
        publish()
    }

    /// Call whenever fresh track info arrives.
    func update(_ data: NowPlaying) {
        self.data = data
        publish()
    }

    private func publish() {
        guard hasPlayed else { return }

        let track = data?.current
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track?.title ?? "Air Break",
            MPMediaItemPropertyArtist: track?.artist ?? "KEXP 90.3 FM",
            MPNowPlayingInfoPropertyIsLiveStream: true,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
        ]
        if let album = track?.album, !album.isEmpty {
            info[MPMediaItemPropertyAlbumTitle] = album
        }
        if let show = data?.showName {
            info[MPMediaItemPropertyAlbumArtist] = show
        }
        if let artwork = Self.artwork(from: track?.artwork ?? Self.appIconData) {
            info[MPMediaItemPropertyArtwork] = artwork
        }

        center.nowPlayingInfo = info
        // macOS-only, and required on every start/stop for remote controls to work.
        center.playbackState = isPlaying ? .playing : .paused
    }

    /// Air breaks and tracks without art show the KEXP app icon.
    private static let appIconData: Data? = NSApp.applicationIconImage?.tiffRepresentation

    /// `nonisolated` matters: MediaPlayer invokes the request handler on its own background
    /// queue, and a closure formed in a @MainActor context would trap there.
    nonisolated private static func artwork(from data: Data?) -> MPMediaItemArtwork? {
        guard let data, let image = NSImage(data: data) else { return nil }
        let size = image.size
        // Rebuild the image from bytes rather than capturing a non-Sendable NSImage.
        return MPMediaItemArtwork(boundsSize: size) { @Sendable _ in NSImage(data: data) ?? NSImage() }
    }
}

import AVFoundation
import Observation
import OSLog
import WidgetKit

/// Owns the KEXP live stream and keeps the widget in sync with play state.
@MainActor
@Observable
final class RadioPlayer {
    static let shared = RadioPlayer()

    private(set) var isPlaying = false
    private(set) var lastError: String?

    private var player: AVPlayer?
    private var statusObservation: NSKeyValueObservation?
    /// Consecutive stream failures; reset once the stream is ready.
    private var failures = 0
    private let log = Logger(subsystem: SharedState.appDomain, category: "RadioPlayer")

    private init() {
        SharedState.isPlaying = false
    }

    func toggle() {
        isPlaying ? pause() : play()
    }

    func play() {
        log.info("play \(KEXP.streamURL, privacy: .public)")
        // Always start a fresh item so a resumed live stream isn't stale.
        let item = AVPlayerItem(url: KEXP.streamURL)
        let player = AVPlayer(playerItem: item)
        statusObservation = item.observe(\.status) { [weak self] item, _ in
            let status = item.status
            let message = item.error?.localizedDescription
            Task { @MainActor in self?.itemStatusChanged(status, error: message) }
        }
        player.play()
        self.player = player
        lastError = nil
        setPlaying(true)
    }

    func pause() {
        log.info("pause")
        statusObservation = nil
        player?.pause()
        player = nil
        setPlaying(false)
    }

    private func itemStatusChanged(_ status: AVPlayerItem.Status, error: String?) {
        switch status {
        case .readyToPlay:
            log.info("stream ready")
            failures = 0
        case .failed:
            log.error("stream failed: \(error ?? "unknown", privacy: .public)")
            failures += 1
            guard failures <= 3, isPlaying else {
                failures = 0
                lastError = error ?? "Couldn’t play the KEXP stream."
                pause()
                return
            }
            // Reconnect with backoff: 2s, 4s, 8s.
            let delay = Duration.seconds(1 << failures)
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: delay)
                guard let self, self.isPlaying else { return }
                self.play()
            }
        default:
            break
        }
    }

    private func setPlaying(_ playing: Bool) {
        isPlaying = playing
        SharedState.isPlaying = playing
        SystemNowPlaying.shared.setPlaying(playing)
        WidgetCenter.shared.reloadTimelines(ofKind: SharedState.widgetKind)
    }
}

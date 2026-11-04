import Foundation
import Observation
import WidgetKit

/// Polls the KEXP API while the app runs and pushes track changes to the widget.
@MainActor
@Observable
final class NowPlayingModel {
    private(set) var data: NowPlaying?
    private(set) var lastError: String?

    private let client = KEXPClient()
    private var pollTask: Task<Void, Never>?

    init() {
        start()
    }

    func start() {
        guard pollTask == nil else { return }
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                // Check often while listening; ease off when paused (the widget still gets updates).
                let interval: Duration = RadioPlayer.shared.isPlaying ? .seconds(30) : .seconds(120)
                try? await Task.sleep(for: interval)
            }
        }
    }

    func refresh() async {
        do {
            // The app only shows the current track (in macOS Now Playing), so skip recent tracks' art.
            let fresh = try await client.nowPlaying(recentCount: 3, includeArtwork: true, recentArtworkCount: 0)
            let changed = fresh.current?.id != data?.current?.id || fresh.showName != data?.showName
            data = fresh
            lastError = nil
            SystemNowPlaying.shared.update(fresh)
            if changed {
                WidgetCenter.shared.reloadTimelines(ofKind: SharedState.widgetKind)
            }
        } catch {
            lastError = error.localizedDescription
        }
    }
}

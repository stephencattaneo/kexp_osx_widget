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
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }

    func refresh() async {
        do {
            let fresh = try await client.nowPlaying(recentCount: 3, includeArtwork: true, recentArtworkCount: 3)
            let changed = fresh.current?.id != data?.current?.id || fresh.showName != data?.showName
            data = fresh
            lastError = nil
            if changed {
                WidgetCenter.shared.reloadTimelines(ofKind: SharedState.widgetKind)
            }
        } catch {
            lastError = error.localizedDescription
        }
    }
}

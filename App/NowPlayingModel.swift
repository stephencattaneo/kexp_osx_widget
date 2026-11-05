import AppKit
import Observation
import OSLog
import WidgetKit

/// Polls the KEXP API while the app runs and pushes track changes to the widget.
@MainActor
@Observable
final class NowPlayingModel {
    private(set) var data: NowPlaying?
    private(set) var lastError: String?

    private let client = KEXPClient()
    private var pollTask: Task<Void, Never>?
    private var wakeObserver: NSObjectProtocol?

    init() {
        start()
        // The network is often down for a moment after sleep, so the widget may have
        // rendered an error; refresh it as soon as we're back.
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(3))
                await self?.refresh(forceWidgetReload: true)
            }
        }
    }

    func start() {
        guard pollTask == nil else { return }
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                // Retry sooner after a failure.
                let failed = self?.lastError != nil
                try? await Task.sleep(for: .seconds(failed ? 10 : 30))
            }
        }
    }

    func refresh(forceWidgetReload: Bool = false) async {
        do {
            let fresh = try await client.nowPlaying(recentCount: 3, includeArtwork: true, recentArtworkCount: 3)
            // Also reload after recovering from an error or when artwork newly arrived: the
            // widget fetches on its own and may be showing the error or missing images.
            let recovered = lastError != nil
            let artworkArrived = fresh.current?.artwork != nil && data?.current?.artwork == nil
            let changed = forceWidgetReload || recovered || artworkArrived
                || fresh.current?.id != data?.current?.id || fresh.showName != data?.showName
            data = fresh
            lastError = nil
            SystemNowPlaying.shared.update(fresh)
            if changed {
                WidgetCenter.shared.reloadTimelines(ofKind: SharedState.widgetKind)
            }
        } catch {
            Logger(subsystem: SharedState.appDomain, category: "Model").error("refresh failed: \(error.localizedDescription, privacy: .public)")
            lastError = error.localizedDescription
        }
    }
}

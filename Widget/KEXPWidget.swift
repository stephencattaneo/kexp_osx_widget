import WidgetKit
import SwiftUI

struct NowPlayingEntry: TimelineEntry {
    let date: Date
    let data: NowPlaying
    let playing: Bool
}

struct NowPlayingProvider: TimelineProvider, Sendable {
    private let client = KEXPClient()

    func placeholder(in context: Context) -> NowPlayingEntry {
        NowPlayingEntry(date: .now, data: .placeholder, playing: false)
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (NowPlayingEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        let family = context.family
        Task { completion(await entry(for: family)) }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<NowPlayingEntry>) -> Void) {
        let family = context.family
        Task {
            let entry = await entry(for: family)
            // Songs run ~3–4 minutes; the host app also reloads us on every track change.
            let next = Date.now.addingTimeInterval(90)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func entry(for family: WidgetFamily) async -> NowPlayingEntry {
        let playing = SharedState.isPlaying
        do {
            let data = try await client.nowPlaying(
                recentCount: 3,
                includeArtwork: true,
                recentArtworkCount: family == .systemLarge ? 3 : 0
            )
            return NowPlayingEntry(date: .now, data: data, playing: playing)
        } catch {
            var data = NowPlaying.placeholder
            data.current = nil
            data.recent = []
            data.showName = "Couldn’t reach KEXP"
            return NowPlayingEntry(date: .now, data: data, playing: playing)
        }
    }
}

struct KEXPWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var scheme
    var entry: NowPlayingEntry

    var body: some View {
        let theme = KEXPTheme.of(scheme)
        Group {
            switch family {
            case .systemSmall: SmallNowPlayingView(data: entry.data, playing: entry.playing)
            case .systemLarge: LargeNowPlayingView(data: entry.data, playing: entry.playing)
            default: MediumNowPlayingView(data: entry.data, playing: entry.playing)
            }
        }
        .environment(\.kexpTheme, theme)
        .containerBackground(theme.background, for: .widget)
    }
}

struct KEXPNowPlayingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: SharedState.widgetKind, provider: NowPlayingProvider()) { entry in
            KEXPWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("KEXP Now Playing")
        .description("What’s on KEXP 90.3 FM right now, with live stream controls.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

@main
struct KEXPWidgetBundle: WidgetBundle {
    var body: some Widget {
        KEXPNowPlayingWidget()
    }
}

#Preview(as: .systemMedium) {
    KEXPNowPlayingWidget()
} timeline: {
    NowPlayingEntry(date: .now, data: .placeholder, playing: false)
    NowPlayingEntry(date: .now, data: .placeholder, playing: true)
}

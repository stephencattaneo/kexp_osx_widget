import SwiftUI

private extension NowPlaying {
    var title: String { current?.title ?? "Air Break" }
    var artist: String { current?.artist ?? "KEXP 90.3 FM" }
}

// MARK: - Small · 170×170

struct SmallNowPlayingView: View {
    @Environment(\.kexpTheme) private var theme
    var data: NowPlaying
    var playing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                NowPlayingArtwork(data: data, size: 64, cornerRadius: 8)
                Spacer()
                PlayPauseButton(playing: playing, diameter: 44)
            }
            Spacer(minLength: 0)
            HStack(spacing: 5) {
                LiveBadge(playing: playing, compact: true)
                Spacer()
                KEXPLogo(width: 15)
            }
            Text(data.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(theme.text)
                .lineLimit(2)
                .padding(.top, 6)
            Text(data.artist)
                .font(.system(size: 12))
                .foregroundStyle(theme.secondary)
                .lineLimit(1)
                .padding(.top, 2)
        }
        .padding(15)
    }
}

// MARK: - Medium · 364×170

struct MediumNowPlayingView: View {
    @Environment(\.kexpTheme) private var theme
    var data: NowPlaying
    var playing: Bool

    var body: some View {
        HStack(spacing: 14) {
            NowPlayingArtwork(data: data, size: 138, cornerRadius: 10)
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    LiveBadge(playing: playing)
                    Spacer()
                    KEXPLogo(width: 18)
                }
                Text(data.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.text)
                    .lineLimit(2)
                    .padding(.top, 10)
                Text(data.artist)
                    .font(.system(size: 13))
                    .foregroundStyle(theme.secondary)
                    .lineLimit(1)
                    .padding(.top, 3)
                Spacer(minLength: 0)
                HStack(alignment: .center, spacing: 10) {
                    if let show = data.showName {
                        ShowLink(id: data.showID) { ShowLine(name: show) }
                    }
                    Spacer(minLength: 0)
                    PlayPauseButton(playing: playing, diameter: 38)
                }
            }
        }
        .padding(16)
    }
}

// MARK: - Large · 364×382

struct LargeNowPlayingView: View {
    @Environment(\.kexpTheme) private var theme
    var data: NowPlaying
    var playing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                KEXPLogo(width: 18)
                Text("KEXP").font(.system(size: 13, weight: .bold)).tracking(1).foregroundStyle(theme.text)
                Text("90.3 FM").font(.system(size: 12)).foregroundStyle(theme.tertiary)
                Spacer()
                LiveBadge(playing: playing)
            }
            .frame(height: 18)

            HStack(spacing: 14) {
                NowPlayingArtwork(data: data, size: 88, cornerRadius: 10)
                VStack(alignment: .leading, spacing: 3) {
                    Text(data.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(theme.text)
                        .lineLimit(2)
                    Text(data.artist)
                        .font(.system(size: 14))
                        .foregroundStyle(theme.secondary)
                        .lineLimit(1)
                    if let album = data.current?.album, !album.isEmpty {
                        Text(album)
                            .font(.system(size: 12))
                            .foregroundStyle(theme.muted)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                PlayPauseButton(playing: playing, diameter: 48)
            }
            .padding(.top, 14)

            if let show = data.showName {
                ShowLink(id: data.showID) {
                    HStack(spacing: 10) {
                        Circle().fill(theme.logo.opacity(0.16)).frame(width: 28, height: 28)
                            .overlay(Image(systemName: "mic").font(.system(size: 12, weight: .medium)).foregroundStyle(theme.logo))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("ON AIR").font(.system(size: 10, weight: .semibold)).tracking(0.6).foregroundStyle(theme.muted)
                            Text(show).font(.system(size: 13, weight: .medium)).foregroundStyle(theme.text).lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 12)
                .overlay(alignment: .top) { Rectangle().fill(theme.divider).frame(height: 1) }
                .padding(.top, 14)
            }

            // The whole track-history block opens the full playlist on kexp.org.
            Link(destination: SharedState.widgetLink(SharedState.playlistURL, web: KEXP.websiteURL)) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("RECENTLY PLAYED")
                        .font(.system(size: 10, weight: .semibold)).tracking(0.6)
                        .foregroundStyle(theme.muted)

                    VStack(spacing: 8) {
                        ForEach(data.recent.prefix(3), id: \.id) { track in
                            RecentRow(track: track)
                        }
                    }
                    .padding(.top, 8)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open the KEXP playlist")
            .padding(.top, 14)
            Spacer(minLength: 0)
        }
        .padding(16)
    }
}

struct RecentRow: View {
    @Environment(\.kexpTheme) private var theme
    var track: TrackInfo

    var body: some View {
        HStack(spacing: 10) {
            ArtworkView(data: track.artwork, size: 36, cornerRadius: 6)
            VStack(alignment: .leading, spacing: 1) {
                Text(track.title).font(.system(size: 13, weight: .medium)).foregroundStyle(theme.text).lineLimit(1)
                Text(track.artist).font(.system(size: 12)).foregroundStyle(theme.secondary).lineLimit(1)
            }
            Spacer(minLength: 0)
            Text(track.airdate, format: .dateTime.hour().minute())
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(theme.muted)
        }
        .frame(height: 36)
    }
}

/// Makes `content` open the current show's page on kexp.org, when the show is known.
struct ShowLink<Content: View>: View {
    var id: Int?
    @ViewBuilder var content: Content

    var body: some View {
        if let id {
            Link(destination: SharedState.widgetLink(SharedState.showURL(id: id), web: KEXP.showURL(id: id))) {
                content.contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open this show on kexp.org")
        } else {
            content
        }
    }
}

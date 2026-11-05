import SwiftUI

private extension NowPlaying {
    var title: String { current?.title ?? "Air Break" }
    var artist: String { current?.artist ?? "KEXP 90.3 FM" }
}

// MARK: - Small · 170×170

/// Full-bleed artwork with the status pill and play button floating over it, and the
/// track in a band along the bottom.
struct SmallNowPlayingView: View {
    @Environment(\.kexpTheme) private var theme
    var data: NowPlaying
    var playing: Bool

    /// Overlay chrome sits on artwork of any color, so it always uses dark scrims.
    private static let scrim = Color.black.opacity(0.6)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FullBleedArtwork(data: data)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .overlay(alignment: .top) {
                    HStack(alignment: .top) {
                        HStack(spacing: 6) {
                            KEXPLogo(width: 13)
                            LiveBadge(playing: playing, offline: data.offline, compact: true)
                        }
                        .padding(.horizontal, 8)
                        .frame(height: 19)
                        .background(Capsule().fill(Self.scrim))
                        Spacer(minLength: 0)
                        PlayPauseButton(playing: playing, diameter: 32, backdrop: Self.scrim)
                    }
                    .padding(12)
                    .environment(\.kexpTheme, .dark)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(data.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.text)
                    .lineLimit(1)
                HStack(alignment: .center, spacing: 4) {
                    Text(data.artist)
                        .font(.system(size: 12))
                        .foregroundStyle(theme.secondary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    AppControls()
                }
            }
            .padding(.horizontal, 15)
            .padding(.top, 9)
            .padding(.bottom, 12)
            .background(theme.background)
            .layoutPriority(1)
        }
    }
}

/// The current artwork filling its frame (cropped to fit), or the KEXP mark during an
/// air break or when a track has no art.
struct FullBleedArtwork: View {
    @Environment(\.kexpTheme) private var theme
    var data: NowPlaying

    var body: some View {
        // The image fills whatever space the layout leaves; it never sizes the layout itself.
        theme.artFill
            .overlay {
                if let bytes = data.current?.artwork, let image = NSImage(data: bytes) {
                    Image(nsImage: image).resizable().scaledToFill()
                } else {
                    KEXPMark().fill(data.current == nil ? theme.logo : theme.artGlyph)
                        .frame(width: 56, height: 56 * 112 / 130)
                }
            }
            .clipped()
            .accessibilityHidden(true)
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
                HStack(alignment: .center, spacing: 8) {
                    KEXPLogo(width: 16)
                    LiveBadge(playing: playing, offline: data.offline)
                    Spacer(minLength: 0)
                    PlayPauseButton(playing: playing, diameter: 32)
                }
                Text(data.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.text)
                    .lineLimit(2)
                    .padding(.top, 6)
                Text(data.artist)
                    .font(.system(size: 13))
                    .foregroundStyle(theme.secondary)
                    .lineLimit(1)
                    .padding(.top, 3)
                Spacer(minLength: 0)
                HStack(alignment: .bottom, spacing: 10) {
                    if let show = data.showName {
                        ShowLink(id: data.showID) { ShowLine(name: show) }
                    }
                    Spacer(minLength: 0)
                    AppControls()
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
                LiveBadge(playing: playing, offline: data.offline)
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
            .padding(.top, 12)

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
                .padding(.top, 10)
                .overlay(alignment: .top) { Rectangle().fill(theme.divider).frame(height: 1) }
                .padding(.top, 12)
            }

            // The whole track-history block opens the full playlist on kexp.org.
            Link(destination: SharedState.widgetLink(SharedState.playlistURL, web: KEXP.websiteURL)) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("RECENTLY PLAYED")
                        .font(.system(size: 10, weight: .semibold)).tracking(0.6)
                        .foregroundStyle(theme.muted)

                    VStack(spacing: 6) {
                        ForEach(data.recent.prefix(3), id: \.id) { track in
                            RecentRow(track: track)
                        }
                    }
                    .padding(.top, 6)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open the KEXP playlist")
            .padding(.top, 12)
            Spacer(minLength: 0)
            HStack {
                Spacer()
                AppControls()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }
}

struct RecentRow: View {
    @Environment(\.kexpTheme) private var theme
    var track: TrackInfo

    var body: some View {
        HStack(spacing: 10) {
            ArtworkView(data: track.artwork, size: 32, cornerRadius: 6)
            VStack(alignment: .leading, spacing: 1) {
                Text(track.title).font(.system(size: 13, weight: .medium)).foregroundStyle(theme.text).lineLimit(1)
                Text(track.artist).font(.system(size: 12)).foregroundStyle(theme.secondary).lineLimit(1)
            }
            Spacer(minLength: 0)
            Text(track.airdate, format: .dateTime.hour().minute())
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(theme.muted)
        }
        .frame(height: 32)
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

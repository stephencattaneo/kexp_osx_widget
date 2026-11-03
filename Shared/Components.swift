import SwiftUI

/// The four-bar KEXP mark (viewBox 130×112).
struct KEXPMark: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 130, sy = rect.height / 112
        let bars: [(x: CGFloat, y: CGFloat, h: CGFloat)] = [(0, 12, 100), (35, 39, 73), (69, 0, 112), (104, 22, 90)]
        var p = Path()
        for b in bars {
            p.addRect(CGRect(x: rect.minX + b.x * sx, y: rect.minY + b.y * sy, width: 25 * sx, height: b.h * sy))
        }
        return p
    }
}

/// The KEXP mark; clicking it opens kexp.org in the default browser.
struct KEXPLogo: View {
    @Environment(\.kexpTheme) private var theme
    var width: CGFloat
    var body: some View {
        Link(destination: KEXP.homeURL) {
            KEXPMark()
                .fill(theme.logo)
                .frame(width: width, height: width * 112 / 130)
                // Enlarge the hit area beyond the small glyph without shifting layout.
                .padding(6)
                .contentShape(Rectangle())
                .padding(-6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open kexp.org")
    }
}

/// Shown in place of album art during an air break: the KEXP mark and wordmark in brand gold.
struct AirBreakArtwork: View {
    @Environment(\.kexpTheme) private var theme
    var size: CGFloat
    var cornerRadius: CGFloat

    var body: some View {
        VStack(spacing: size * 0.06) {
            KEXPMark().fill(theme.logo)
                .frame(width: size * 0.5, height: size * 0.5 * 112 / 130)
            if size >= 60 {
                Text("KEXP")
                    .font(.system(size: size * 0.13, weight: .bold))
                    .tracking(size * 0.015)
                    .foregroundStyle(theme.logo)
            }
        }
        .frame(width: size, height: size)
        .background(theme.artFill)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(theme.artBorder, lineWidth: 1))
        .accessibilityLabel("KEXP air break")
    }
}

/// Album art for the current slot: the KEXP logo during an air break, otherwise the
/// track's artwork (or a dimmed mark when it has none).
struct NowPlayingArtwork: View {
    var data: NowPlaying
    var size: CGFloat
    var cornerRadius: CGFloat

    var body: some View {
        if let track = data.current {
            ArtworkView(data: track.artwork, size: size, cornerRadius: cornerRadius)
        } else {
            AirBreakArtwork(size: size, cornerRadius: cornerRadius)
        }
    }
}

/// Album art, or the dimmed KEXP mark when none is available.
struct ArtworkView: View {
    @Environment(\.kexpTheme) private var theme
    var data: Data?
    var size: CGFloat
    var cornerRadius: CGFloat

    var body: some View {
        ZStack {
            theme.artFill
            if let data, let image = NSImage(data: data) {
                Image(nsImage: image).resizable().aspectRatio(contentMode: .fill)
            } else {
                KEXPMark().fill(theme.artGlyph)
                    .frame(width: size * 0.46, height: size * 0.46 * 112 / 130)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(theme.artBorder, lineWidth: 1))
        .accessibilityHidden(true)
    }
}

/// Red dot + "LIVE" (+ static EQ bars when playing).
struct LiveBadge: View {
    @Environment(\.kexpTheme) private var theme
    var playing: Bool
    var compact = false

    var body: some View {
        HStack(spacing: compact ? 5 : 6) {
            Circle().fill(theme.liveHalo)
                .frame(width: compact ? 12 : 14, height: compact ? 12 : 14)
                .overlay(Circle().fill(theme.live).frame(width: compact ? 6 : 7, height: compact ? 6 : 7))
            Text("LIVE")
                .font(.system(size: compact ? 10 : 11, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(theme.liveText)
            if playing { EQBars() }
        }
    }
}

struct EQBars: View {
    @Environment(\.kexpTheme) private var theme
    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach([0.55, 1.0, 0.75], id: \.self) { h in
                RoundedRectangle(cornerRadius: 1).fill(theme.liveText).frame(width: 2, height: 9 * h)
            }
        }
        .frame(height: 9, alignment: .bottom)
        .accessibilityHidden(true)
    }
}

/// Circular outlined play/pause button. In the widget it's a link to
/// `kexpnowplaying://toggle` (handled by the host app); in the app it toggles directly.
struct PlayPauseButton: View {
    @Environment(\.kexpTheme) private var theme
    var playing: Bool
    var diameter: CGFloat

    var body: some View {
        #if WIDGET_EXTENSION
        Link(destination: SharedState.toggleURL) { face }
            .accessibilityLabel(label)
        #else
        Button { RadioPlayer.shared.toggle() } label: { face }
            .buttonStyle(.plain)
            .accessibilityLabel(label)
        #endif
    }

    private var label: String { playing ? "Pause KEXP" : "Play KEXP live" }

    private var face: some View {
        ZStack {
            Circle().strokeBorder(theme.accent, lineWidth: 2.5)
            Image(systemName: playing ? "pause.fill" : "play.fill")
                .font(.system(size: diameter * 0.36, weight: .bold))
                .foregroundStyle(theme.accent)
                .offset(x: playing ? 0 : diameter * 0.04)
        }
        .frame(width: diameter, height: diameter)
        .contentShape(Circle())
    }
}

struct ShowLine: View {
    @Environment(\.kexpTheme) private var theme
    var name: String
    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            Image(systemName: "mic").font(.system(size: 10, weight: .medium)).accessibilityHidden(true)
            Text(name).font(.system(size: 11)).lineLimit(2)
        }
        .foregroundStyle(theme.tertiary)
    }
}

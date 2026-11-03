import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

/// Palette from the "KEXP Now Playing Widget" design canvas.
struct KEXPTheme {
    let background: Color
    let artFill: Color
    let artBorder: Color
    let artGlyph: Color
    let text: Color
    let secondary: Color
    let tertiary: Color
    let muted: Color
    let accent: Color
    let logo: Color
    let live: Color
    let liveHalo: Color
    let liveText: Color
    let divider: Color

    static let dark = KEXPTheme(
        background: Color(hex: 0x231F20),
        artFill: Color(hex: 0x2C2829),
        artBorder: .white.opacity(0.16),
        artGlyph: Color(hex: 0x3E3A3B),
        text: Color(hex: 0xF5F3F2),
        secondary: Color(hex: 0xF5F3F2, opacity: 0.72),
        tertiary: Color(hex: 0xF5F3F2, opacity: 0.62),
        muted: Color(hex: 0xF5F3F2, opacity: 0.60),
        accent: Color(hex: 0xF2A93B),
        logo: Color(hex: 0xC9993C),
        live: Color(hex: 0xE24C4C),
        liveHalo: Color(hex: 0xE24C4C, opacity: 0.22),
        liveText: Color(hex: 0xEE9C98),
        divider: .white.opacity(0.10)
    )

    static let light = KEXPTheme(
        background: Color(hex: 0xFBF9F6),
        artFill: Color(hex: 0xEFEBE7),
        artBorder: Color(hex: 0x231F20, opacity: 0.12),
        artGlyph: Color(hex: 0xD8D2CC),
        text: Color(hex: 0x231F20),
        secondary: Color(hex: 0x231F20, opacity: 0.72),
        tertiary: Color(hex: 0x231F20, opacity: 0.66),
        muted: Color(hex: 0x231F20, opacity: 0.62),
        accent: Color(hex: 0xC47A12),
        logo: Color(hex: 0xB5852A),
        live: Color(hex: 0xD83B3B),
        liveHalo: Color(hex: 0xD83B3B, opacity: 0.16),
        liveText: Color(hex: 0xB42F2F),
        divider: Color(hex: 0x231F20, opacity: 0.10)
    )

    static func of(_ scheme: ColorScheme) -> KEXPTheme { scheme == .dark ? .dark : .light }
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = KEXPTheme.dark
}

extension EnvironmentValues {
    var kexpTheme: KEXPTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

/// Injects the theme matching the current color scheme.
struct ThemedByScheme: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        content.environment(\.kexpTheme, .of(scheme))
    }
}

extension View {
    func kexpThemed() -> some View { modifier(ThemedByScheme()) }
}

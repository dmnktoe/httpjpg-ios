import SwiftUI
import Tokens

private struct ChromeAccentKey: EnvironmentKey {
    static let defaultValue: Color? = nil
}

private struct GlassNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

public extension EnvironmentValues {
    /// Soft tint derived from the first featured work image (or nil for theme chrome).
    var chromeAccent: Color? {
        get { self[ChromeAccentKey.self] }
        set { self[ChromeAccentKey.self] = newValue }
    }

    /// Shared liquid-glass morph namespace for chrome across sidebar / tabs / player.
    var glassNamespace: Namespace.ID? {
        get { self[GlassNamespaceKey.self] }
        set { self[GlassNamespaceKey.self] = newValue }
    }
}

public extension View {
    func chromeAccent(_ color: Color?) -> some View {
        environment(\.chromeAccent, color)
    }

    func glassNamespace(_ id: Namespace.ID) -> some View {
        environment(\.glassNamespace, id)
    }
}

public extension PageTheme {
    /// Inactive chrome fill — accent-tinted when a featured color is present.
    func chromeFill(accent: Color?) -> Color {
        guard let accent else { return chromeFill }
        return accent.opacity(isDark ? 0.42 : 0.32)
    }

    /// Selected chrome fill — keeps high contrast, with a whisper of accent on the stroke side.
    func chromeActiveFill(accent: Color?) -> Color {
        guard accent != nil else { return chromeActiveFill }
        return Palette.white.opacity(isDark ? 0.92 : 0.96)
    }

    func chromeStroke(accent: Color?) -> Color {
        guard let accent else { return chromeStroke }
        return accent.opacity(isDark ? 0.55 : 0.4)
    }

    func chromeActiveStroke(accent: Color?) -> Color {
        accent?.opacity(0.85) ?? chromeActiveStroke
    }
}

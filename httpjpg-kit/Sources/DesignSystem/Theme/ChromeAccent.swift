import SwiftUI
import Tokens

private struct ChromeAccentKey: EnvironmentKey {
    static let defaultValue: Color? = nil
}

private struct ChromeOnAccentKey: EnvironmentKey {
    static let defaultValue: Color? = nil
}

private struct GlassNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

public extension EnvironmentValues {
    var chromeAccent: Color? {
        get { self[ChromeAccentKey.self] }
        set { self[ChromeAccentKey.self] = newValue }
    }

    var chromeOnAccent: Color? {
        get { self[ChromeOnAccentKey.self] }
        set { self[ChromeOnAccentKey.self] = newValue }
    }

    var glassNamespace: Namespace.ID? {
        get { self[GlassNamespaceKey.self] }
        set { self[GlassNamespaceKey.self] = newValue }
    }
}

public extension View {
    func chromeAccent(_ color: Color?, onAccent: Color? = nil) -> some View {
        environment(\.chromeAccent, color)
            .environment(\.chromeOnAccent, onAccent)
    }

    func glassNamespace(_ id: Namespace.ID) -> some View {
        environment(\.glassNamespace, id)
    }
}

public extension PageTheme {
    func chromeFill(accent: Color?) -> Color {
        guard let accent else { return chromeFill }
        return accent.opacity(isDark ? 0.62 : 0.5)
    }

    func chromeActiveFill(accent: Color?) -> Color {
        guard accent != nil else { return chromeActiveFill }
        return Palette.white.opacity(isDark ? 0.92 : 0.96)
    }

    func chromeStroke(accent: Color?) -> Color {
        guard let accent else { return chromeStroke }
        return accent.opacity(isDark ? 0.7 : 0.55)
    }

    func chromeActiveStroke(accent: Color?) -> Color {
        accent ?? chromeActiveStroke
    }

    func chromeLabel(onAccent: Color?) -> Color {
        onAccent ?? chromeLabel
    }
}

import SwiftUI
import Tokens

private struct ChromeAccentKey: EnvironmentKey {
    static let defaultValue: Color? = nil
}

private struct ChromeOnAccentKey: EnvironmentKey {
    static let defaultValue: Color? = nil
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
}

public extension View {
    func chromeAccent(_ color: Color?, onAccent: Color? = nil) -> some View {
        environment(\.chromeAccent, color)
            .environment(\.chromeOnAccent, onAccent)
    }
}

public extension PageTheme {
    func chromeFill(accent: Color?) -> Color {
        guard let accent else { return chromeFill }
        return accent.opacity(isDark ? 0.7 : 0.62)
    }

    func chromeActiveFill(accent: Color?) -> Color {
        guard accent != nil else { return chromeActiveFill }
        return Palette.white.opacity(isDark ? 0.92 : 0.96)
    }

    func chromeStroke(accent: Color?) -> Color {
        guard let accent else { return chromeStroke }
        return accent.opacity(isDark ? 0.75 : 0.6)
    }

    func chromeActiveStroke(accent: Color?) -> Color {
        accent ?? chromeActiveStroke
    }

    func chromeLabel(onAccent: Color?) -> Color {
        onAccent ?? chromeLabel
    }
}

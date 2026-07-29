import SwiftUI

public struct PageTheme: Sendable, Equatable {
    public enum Appearance: String, Sendable, CaseIterable, Identifiable {
        case light
        case dark

        public var id: String { rawValue }
    }

    public var appearance: Appearance

    public init(appearance: Appearance = .light) {
        self.appearance = appearance
    }

    public static let light = PageTheme(appearance: .light)
    public static let dark = PageTheme(appearance: .dark)

    public var isDark: Bool { appearance == .dark }

    public var background: Color { isDark ? Palette.black : Palette.white }

    public var foreground: Color { isDark ? Palette.white : Palette.black }

    public var muted: Color { isDark ? Palette.neutral.s300 : Palette.neutral.s700 }

    public var border: Color { isDark ? Palette.neutral.s700 : Palette.neutral.s300 }

    public var link: Color { Palette.primary.s500 }

    public var colorScheme: ColorScheme { isDark ? .dark : .light }
}

private struct PageThemeKey: EnvironmentKey {
    static let defaultValue = PageTheme.light
}

public extension EnvironmentValues {
    var pageTheme: PageTheme {
        get { self[PageThemeKey.self] }
        set { self[PageThemeKey.self] = newValue }
    }
}

public extension View {
    func pageTheme(_ theme: PageTheme) -> some View {
        environment(\.pageTheme, theme)
            .environment(\.colorScheme, theme.colorScheme)
            .tint(theme.link)
    }

    func pageSurface(_ theme: PageTheme) -> some View {
        foregroundStyle(theme.foreground)
            .background(theme.background.ignoresSafeArea())
    }
}

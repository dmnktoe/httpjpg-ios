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

    public var drawerBackground: Color { isDark ? Palette.neutral.s900 : Palette.white }

    public var muted: Color { isDark ? Palette.neutral.s300 : Palette.neutral.s700 }

    public var border: Color { isDark ? Palette.neutral.s700 : Palette.neutral.s300 }

    public var link: Color { Palette.primary.s500 }

    public var codeChipBackground: Color {
        isDark ? Palette.neutral.s800 : Palette.neutral.s100
    }

    public var chromeFill: Color { isDark ? Palette.neutral.s900.opacity(0.55) : Palette.white.opacity(0.5) }

    public var chromeLabel: Color { isDark ? Palette.white.opacity(0.92) : Palette.neutral.s800 }

    public var chromeStroke: Color { foreground.opacity(isDark ? 0.16 : 0.12) }

    public var chromeActiveFill: Color { foreground.opacity(0.92) }

    public var chromeActiveLabel: Color { background }

    public var chromeActiveStroke: Color { foreground }

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

    func pageSurface(forcingDark: Bool) -> some View {
        modifier(ForcedPageSurface(forcesDark: forcingDark))
    }
}

private struct ForcedPageSurface: ViewModifier {
    let forcesDark: Bool

    @Environment(\.pageTheme) private var ambient

    func body(content: Content) -> some View {
        let theme = forcesDark ? PageTheme.dark : ambient
        let surface = content
            .pageTheme(theme)
            .pageSurface(theme)

        #if os(iOS)
        return surface.toolbarColorScheme(forcesDark ? .dark : nil, for: .navigationBar)
        #else
        return surface
        #endif
    }
}

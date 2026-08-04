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

    /// Floating glass chrome: tab pills, mini player, preview pill. Idle
    /// elements sit on a quiet grey; the active pill pops to a plain white
    /// card with a black label in both appearances.
    public var chromeFill: Color { isDark ? Palette.neutral.s800.opacity(0.72) : Palette.neutral.s300.opacity(0.6) }

    public var chromeLabel: Color { isDark ? Palette.white.opacity(0.9) : Palette.neutral.s800 }

    public var chromeStroke: Color { Palette.neutral.s400.opacity(isDark ? 0.6 : 0.45) }

    public var chromeActiveFill: Color { Palette.white.opacity(0.95) }

    public var chromeActiveLabel: Color { Palette.black }

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

    /// Surface for CMS-driven documents: a page can force dark art direction,
    /// everything else follows the ambient theme — so system dark mode also
    /// darkens pages that don't specify.
    func pageSurface(forcingDark: Bool) -> some View {
        modifier(ForcedPageSurface(forcesDark: forcingDark))
    }
}

private struct ForcedPageSurface: ViewModifier {
    let forcesDark: Bool

    @Environment(\.pageTheme) private var ambient

    func body(content: Content) -> some View {
        let theme = forcesDark ? PageTheme.dark : ambient
        return content
            .pageTheme(theme)
            .pageSurface(theme)
            // The colorScheme environment doesn't reach the UIKit navigation
            // bar or the status bar; without this a forced-dark page draws
            // its title and status bar black-on-black in a light system.
            .toolbarColorScheme(theme.colorScheme, for: .navigationBar)
    }
}

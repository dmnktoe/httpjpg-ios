import SwiftUI

/// The semantic colour layer — the Swift counterpart of Panda's `pageBg`,
/// `pageFg`, `pageMuted` and `pageBorder` semantic tokens.
///
/// On the web the flip is driven by `[data-theme=dark]`, which the portfolio
/// sets per story from the `isDark` field. The app does the same: a story
/// carries an appearance, the user can override it, and everything below the
/// root reads the resolved value out of the environment.
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

    /// `pageBg` — white in light mode, pure black in dark mode.
    public var background: Color { isDark ? Palette.black : Palette.white }

    /// `pageFg` — the inverse of ``background``.
    public var foreground: Color { isDark ? Palette.white : Palette.black }

    /// `pageMuted` — `neutral.700` / `neutral.300`.
    public var muted: Color { isDark ? Palette.neutral.s300 : Palette.neutral.s700 }

    /// `pageBorder` — `neutral.300` / `neutral.700`.
    public var border: Color { isDark ? Palette.neutral.s700 : Palette.neutral.s300 }

    /// The link colour used across work cards and rich text.
    public var link: Color { Palette.primary.s500 }

    /// The SwiftUI colour scheme to force on the subtree, so system controls
    /// (selection, keyboard, scroll indicators) match the page.
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
    /// Applies a page theme to the subtree and paints the surface behind it.
    func pageTheme(_ theme: PageTheme) -> some View {
        environment(\.pageTheme, theme)
            .environment(\.colorScheme, theme.colorScheme)
            .tint(theme.link)
    }

    /// Fills the safe area with `pageBg` and sets `pageFg` as the default
    /// foreground, mirroring the `body { bg: pageBg; color: pageFg }` global.
    func pageSurface(_ theme: PageTheme) -> some View {
        foregroundStyle(theme.foreground)
            .background(theme.background.ignoresSafeArea())
    }
}

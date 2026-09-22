import SwiftUI
import Tokens

public extension View {
    /// Gives a page a real navigation bar: a fill and the hairline under it.
    ///
    /// iOS 26 dissolved both — every bar became clear glass with nothing marking
    /// where it ended, so an inline title floated over the page's own artwork.
    /// iOS 27 brought the separated header back, and this is that header: the
    /// bar takes the page's colour (its accent, where it has one) and a hairline
    /// closes it off. Passing `nil` leaves the system glass alone.
    ///
    /// - Parameters:
    ///   - color: the bar fill, usually the page accent or its surface.
    ///   - scheme: forced to keep the title legible on a dark or light fill; it
    ///     also picks the hairline.
    func navigationBarBackground(_ color: Color?, scheme: ColorScheme? = nil) -> some View {
        modifier(NavigationBarBackground(color: color, scheme: scheme))
    }
}

private struct NavigationBarBackground: ViewModifier {
    let color: Color?
    let scheme: ColorScheme?

    @Environment(\.pageTheme) private var theme

    @ViewBuilder
    func body(content: Content) -> some View {
        if let color {
            filled(content, color: color)
                .toolbarColorScheme(scheme, for: .navigationBar)
        } else {
            content
        }
    }

    @ViewBuilder
    private func filled(_ content: Content, color: Color) -> some View {
        // The bar takes a `ShapeStyle`, not a view, so the hairline is added to
        // the page's top safe area instead. A plain overlay would not do: a
        // `ScrollView` here spans the whole screen and scrolls under the bar, so
        // its top edge is the status bar, not the bar's underside.
        let bordered = content.safeAreaInset(edge: .top, spacing: 0) {
            Rectangle()
                .fill(borderColor)
                .frame(height: PillMetrics.hairline)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }

        if #available(iOS 26.0, *) {
            bordered
                .toolbarBackground(color, for: .navigationBar)
                .toolbarBackgroundVisibility(.visible, for: .navigationBar)
        } else {
            bordered
                .toolbarBackground(color, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    /// Reads against the bar above it, not the page below — a dark bar needs a
    /// light rule whatever the page underneath is doing.
    private var borderColor: Color {
        let isDarkBar = scheme.map { $0 == .dark } ?? theme.isDark
        return isDarkBar
            ? Palette.white.opacity(Self.darkBorderOpacity)
            : Palette.black.opacity(Self.lightBorderOpacity)
    }

    private static let darkBorderOpacity: Double = 0.22

    private static let lightBorderOpacity: Double = 0.14
}

import SwiftUI

public extension View {
    /// Paints the navigation bar behind a page.
    ///
    /// iOS 26 made every bar Liquid Glass, which left an accented work page with
    /// a colourless header sitting over its own artwork. A visible background
    /// puts the page's accent back in the bar and gives the inline title
    /// something to sit on; passing `nil` leaves the system glass alone.
    ///
    /// - Parameters:
    ///   - color: the bar fill, usually the page accent.
    ///   - scheme: forced to keep the title legible on a dark or light fill.
    func navigationBarBackground(_ color: Color?, scheme: ColorScheme? = nil) -> some View {
        modifier(NavigationBarBackground(color: color, scheme: scheme))
    }
}

private struct NavigationBarBackground: ViewModifier {
    let color: Color?
    let scheme: ColorScheme?

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
        if #available(iOS 26.0, *) {
            content
                .toolbarBackground(color, for: .navigationBar)
                .toolbarBackgroundVisibility(.visible, for: .navigationBar)
        } else {
            content
                .toolbarBackground(color, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

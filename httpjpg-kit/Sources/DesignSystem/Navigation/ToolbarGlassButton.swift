import SwiftUI
import Tokens

public extension View {
    /// Colours a button inside a navigation bar, leaving its shape to the system.
    ///
    /// From iOS 26 a toolbar item already carries Liquid Glass — the same
    /// interactive backing the sidebar hamburger uses. An accented control
    /// takes `.glassProminent` with `.tint(accent)` so that backing fills with
    /// the page colour and stays grabable. Painting our own orb (especially an
    /// opaque one) replaced that system glass with a flat disc you could not
    /// move. An unaccented control only sets the glyph to the page foreground:
    /// another `.glass` style nested a second capsule inside the toolbar's, and
    /// `pageTheme`'s link tint would otherwise turn the symbol blue.
    ///
    /// Below iOS 26 there is no glass in the bar to inherit, so the button draws
    /// its own orb.
    ///
    /// - Parameters:
    ///   - accent: the page accent, or `nil` for a neutral control.
    ///   - fallback: how to draw it on iOS 17–25.
    func toolbarGlassButton(_ accent: Color?, fallback: PillTint) -> some View {
        modifier(ToolbarGlassButton(accent: accent, fallback: fallback))
    }
}

private struct ToolbarGlassButton: ViewModifier {
    let accent: Color?
    let fallback: PillTint

    @Environment(\.pageTheme) private var theme

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            native(content)
        } else {
            content.buttonStyle(.glassOrb(fallback))
        }
    }

    @available(iOS 26.0, *)
    @ViewBuilder
    private func native(_ content: Content) -> some View {
        if let accent {
            content
                .buttonStyle(.glassProminent)
                .tint(accent)
        } else {
            // Glyph colour comes from the label (`foregroundStyle`); only kill
            // the ambient link tint so the system does not paint it primary.
            content.tint(fallback.label)
        }
    }
}

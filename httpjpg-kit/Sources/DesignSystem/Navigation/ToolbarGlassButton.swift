import SwiftUI
import Tokens

public extension View {
    /// Colours a button inside a navigation bar, leaving its shape to the system
    /// when untinted.
    ///
    /// Untinted controls on iOS 26 keep the toolbar's Liquid Glass and only set
    /// the glyph. Accented controls use the opaque orb so CMS contrast from
    /// `Palette.onNamed` is exact — `.glassProminent` was choosing its own
    /// label colour from the washed fill and missing mid accents.
    ///
    /// Below iOS 26 every control draws its own orb.
    ///
    /// - Parameters:
    ///   - accent: the page accent, or `nil` for a neutral control.
    ///   - fallback: fill/label/stroke for the orb (and the untinted glyph).
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
        if accent != nil {
            // Opaque CMS accent: keep the orb so `Palette.onNamed` wins.
            // `.glassProminent` picks its own label colour from the washed glass
            // fill and was painting black glyphs on mid accents like `#92a0a0`.
            content.buttonStyle(.glassOrb(fallback))
        } else if #available(iOS 26.0, *) {
            // Untinted: inherit the toolbar's system glass, only set the glyph.
            content.tint(fallback.label)
        } else {
            content.buttonStyle(.glassOrb(fallback))
        }
    }
}

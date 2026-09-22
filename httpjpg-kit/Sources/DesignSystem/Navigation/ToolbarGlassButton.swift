import SwiftUI
import Tokens

public extension View {
    /// Colours a button inside a navigation bar.
    ///
    /// On iOS 26 untinted controls keep the toolbar's Liquid Glass and only set
    /// the glyph. Accented controls use `.glassProminent` so they stay real
    /// system glass, with an explicit `fallback.label` (`Palette.onNamed`) so
    /// mid accents like `#92a0a0` do not fall back to the system's black glyph.
    ///
    /// Below iOS 26 every control draws its own orb.
    ///
    /// - Parameters:
    ///   - accent: the page accent, or `nil` for a neutral control.
    ///   - fallback: fill/label for the orb / prominent glyph.
    func toolbarGlassButton(_ accent: Color?, fallback: PillTint) -> some View {
        modifier(ToolbarGlassButton(accent: accent, fallback: fallback))
    }
}

private struct ToolbarGlassButton: ViewModifier {
    let accent: Color?
    let fallback: PillTint

    @ViewBuilder
    func body(content: Content) -> some View {
        if let accent {
            if #available(iOS 26.0, *) {
                content
                    // Label first so glassProminent cannot substitute its own
                    // contrast pick over `Palette.onNamed`.
                    .foregroundStyle(fallback.label)
                    .buttonStyle(.glassProminent)
                    .buttonBorderShape(.circle)
                    .tint(accent)
            } else {
                content.buttonStyle(.glassOrb(fallback))
            }
        } else if #available(iOS 26.0, *) {
            content.tint(fallback.label)
        } else {
            content.buttonStyle(.glassOrb(fallback))
        }
    }
}

import SwiftUI
import Tokens

public extension View {
    /// Colours a button inside a navigation bar, leaving its shape to the system
    /// when untinted.
    ///
    /// Untinted controls on iOS 26 keep the toolbar's Liquid Glass and only set
    /// the glyph. Accented controls draw their own tinted glass orb so CMS
    /// contrast from `Palette.onNamed` stays exact — `.glassProminent` was
    /// picking its own label colour from the washed fill.
    ///
    /// Pair accented controls with `hidingSharedToolbarBackground(true)` on the
    /// `ToolbarItem`, otherwise the system glass ring sits around the orb.
    ///
    /// Below iOS 26 every control draws its own orb (opaque accent fill).
    ///
    /// - Parameters:
    ///   - accent: the page accent, or `nil` for a neutral control.
    ///   - fallback: fill/label/stroke for the orb (and the untinted glyph).
    func toolbarGlassButton(_ accent: Color?, fallback: PillTint) -> some View {
        modifier(ToolbarGlassButton(accent: accent, fallback: fallback))
    }
}

public extension ToolbarContent {
    /// Drops the iOS 26 shared toolbar glass behind an item. Accent orbs need
    /// this so they fill the circle edge-to-edge instead of floating inside a
    /// second clear ring.
    @ToolbarContentBuilder
    func hidingSharedToolbarBackground(_ hidden: Bool) -> some ToolbarContent {
        if #available(iOS 26.0, *), hidden {
            sharedBackgroundVisibility(.hidden)
        } else {
            self
        }
    }
}

private struct ToolbarGlassButton: ViewModifier {
    let accent: Color?
    let fallback: PillTint

    @ViewBuilder
    func body(content: Content) -> some View {
        if let accent {
            content.buttonStyle(.glassOrb(accentOrb(fill: accent)))
        } else if #available(iOS 26.0, *) {
            // Untinted: inherit the toolbar's system glass, only set the glyph.
            content.tint(fallback.label)
        } else {
            content.buttonStyle(.glassOrb(fallback))
        }
    }

    /// iOS 26: real tinted Liquid Glass (not a flat disc). Older OS keeps the
    /// opaque accent fill from `PillTint.control`.
    private func accentOrb(fill: Color) -> PillTint {
        if #available(iOS 26.0, *) {
            PillTint(fill: fill, label: fallback.label, stroke: nil, isOpaque: false)
        } else {
            fallback
        }
    }
}

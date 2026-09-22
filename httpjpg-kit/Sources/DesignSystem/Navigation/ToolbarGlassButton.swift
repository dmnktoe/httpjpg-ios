import SwiftUI
import Tokens

public extension View {
    /// Colours a navigation-bar button.
    ///
    /// Untinted controls on iOS 26 keep the toolbar's own Liquid Glass (the
    /// round hamburger look) and only set the glyph. Accented controls draw a
    /// tinted `glassEffect` orb so `Palette.onNamed` owns the glyph — pair
    /// those with `hidingSharedToolbarBackground()` so the system ring does
    /// not sit around the orb.
    ///
    /// Below iOS 26 every control draws its own orb.
    func toolbarGlassButton(_ accent: Color?, fallback: PillTint) -> some View {
        modifier(ToolbarGlassButton(accent: accent, fallback: fallback))
    }
}

public extension ToolbarContent {
    /// Hides the iOS 26 shared toolbar glass behind an item that already draws
    /// its own accent orb.
    @ToolbarContentBuilder
    func hidingSharedToolbarBackground(_ hidden: Bool = true) -> some ToolbarContent {
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
            if #available(iOS 26.0, *) {
                content.buttonStyle(.glassOrb(PillTint(
                    fill: accent,
                    label: fallback.label,
                    stroke: nil,
                    isOpaque: false
                )))
            } else {
                content.buttonStyle(.glassOrb(fallback))
            }
        } else if #available(iOS 26.0, *) {
            // System toolbar glass stays circular; only push the glyph colour
            // (needed on forced-dark work pages).
            content
                .foregroundStyle(fallback.label)
                .tint(fallback.label)
        } else {
            content.buttonStyle(.glassOrb(fallback))
        }
    }
}

import SwiftUI
import Tokens

public extension View {
    /// Colours a navigation-bar button with Liquid Glass and an explicit glyph.
    ///
    /// On iOS 26 every control draws its own `glassEffect` orb (tinted when an
    /// accent is set, clear otherwise) so `Palette.onNamed` owns the glyph —
    /// `.glassProminent` ignored that and picked black on mid accents / dark
    /// pages. Pair with `hidingSharedToolbarBackground(true)` so the system
    /// does not wrap a second clear ring around the orb.
    ///
    /// Below iOS 26 the opaque / material orb from `fallback` is used as-is.
    func toolbarGlassButton(_ accent: Color?, fallback: PillTint) -> some View {
        modifier(ToolbarGlassButton(accent: accent, fallback: fallback))
    }
}

public extension ToolbarContent {
    /// Hides the iOS 26 shared toolbar glass behind an item we already glass
    /// ourselves (accent orbs and clear orbs alike).
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
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glassOrb(liquidTint))
        } else {
            content.buttonStyle(.glassOrb(fallback))
        }
    }

    /// Clear or accent-tinted Liquid Glass; never opaque flat fill. Glyph comes
    /// from `fallback.label` (`onNamed` / page foreground).
    private var liquidTint: PillTint {
        PillTint(
            fill: accent,
            label: fallback.label,
            stroke: nil,
            isOpaque: false
        )
    }
}

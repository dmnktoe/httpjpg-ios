import SwiftUI
import Tokens

public extension View {
    /// Colours a navigation-bar button.
    ///
    /// Untinted controls on iOS 26 keep the toolbar's Liquid Glass and only set
    /// the glyph. Accented controls use `.glassProminent` with the CMS accent
    /// so the tint sits inside the system glass (padded circle), with an
    /// explicit `fallback.label` from `Palette.onNamed` for the glyph.
    ///
    /// Below iOS 26 every control draws its own orb.
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
                    .foregroundStyle(fallback.label)
                    .buttonStyle(.glassProminent)
                    .buttonBorderShape(.circle)
                    .tint(accent)
            } else {
                content.buttonStyle(.glassOrb(fallback))
            }
        } else if #available(iOS 26.0, *) {
            content
                .foregroundStyle(fallback.label)
                .tint(fallback.label)
        } else {
            content.buttonStyle(.glassOrb(fallback))
        }
    }
}

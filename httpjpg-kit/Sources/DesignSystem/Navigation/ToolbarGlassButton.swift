import SwiftUI
import Tokens

public extension View {
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
                    .buttonStyle(.glyphPinnedGlassProminent(fallback.label))
                    .tint(accent)
                    .animation(Motion.stateChange, value: accent)
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

// Prominent glass derives its own glyph colour from the tint and the bar's
// colour scheme, and that beats a foregroundStyle set on the button. It also
// settles a frame after the glass during a push between a dark and a light
// page, so the glyph snaps while the tint morphs. Colouring the label itself
// sits inside the style and wins, keeping the glyph on Palette.onNamed.
@available(iOS 26.0, *)
private struct GlyphPinnedGlassProminentButtonStyle: PrimitiveButtonStyle {
    let glyph: Color

    func makeBody(configuration: Configuration) -> some View {
        Button(role: configuration.role, action: configuration.trigger) {
            configuration.label
                .foregroundStyle(glyph)
                .animation(Motion.stateChange, value: glyph)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.circle)
    }
}

@available(iOS 26.0, *)
private extension PrimitiveButtonStyle where Self == GlyphPinnedGlassProminentButtonStyle {
    static func glyphPinnedGlassProminent(_ glyph: Color) -> GlyphPinnedGlassProminentButtonStyle {
        GlyphPinnedGlassProminentButtonStyle(glyph: glyph)
    }
}

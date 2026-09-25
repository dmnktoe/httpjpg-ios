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

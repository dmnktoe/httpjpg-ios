import SwiftUI
import Tokens

/// Glass panel with a border beam that can be switched off; it fades instead of vanishing.
struct CommandPaletteGlass: ViewModifier {
    let cornerRadius: CGFloat
    let isGlowing: Bool

    @Environment(\.pageTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .circular)
    }

    func body(content: Content) -> some View {
        glass(content)
            .overlay {
                shape
                    .strokeBorder(theme.border.opacity(Opacities.subtle), lineWidth: 1)
                    .opacity(isGlowing ? 0 : 1)
                    .animation(reduceMotion ? nil : Motion.glowFade, value: isGlowing)
            }
            .beamOutline(cornerRadius: cornerRadius, isActive: isGlowing)
    }

    @ViewBuilder
    private func glass(_ content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.clear, in: shape)
        } else {
            content.liquidGlass(in: shape)
        }
    }
}

import SwiftUI
import Tokens
#if os(iOS)
import BorderBeam
#endif

/// Glass panel with a border beam that can be switched off; it fades instead of vanishing.
struct CommandPaletteGlass: ViewModifier {
    let cornerRadius: CGFloat
    let isGlowing: Bool

    @Environment(\.pageTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    func body(content: Content) -> some View {
        glass(content)
            // Behind the glass rather than over it, so the beam's glow never washes across the answer text.
            .background { beam }
            .overlay {
                shape
                    .strokeBorder(theme.border.opacity(Opacities.subtle), lineWidth: 1)
                    .opacity(isGlowing ? 0 : 1)
                    .animation(reduceMotion ? nil : Motion.glowFade, value: isGlowing)
            }
    }

    @ViewBuilder
    private func glass(_ content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.clear, in: shape)
        } else {
            content.liquidGlass(in: shape)
        }
    }

    @ViewBuilder
    private var beam: some View {
        #if os(iOS)
        // The beam does its own fade and pauses its timeline once inactive, so an idle panel costs nothing.
        Color.clear
            .borderBeam(
                shape: .rounded(cornerRadius),
                active: isGlowing,
                timing: BeamTiming(fade: reduceMotion ? 0 : Motion.glowFadeDuration)
            )
        #else
        EmptyView()
        #endif
    }
}

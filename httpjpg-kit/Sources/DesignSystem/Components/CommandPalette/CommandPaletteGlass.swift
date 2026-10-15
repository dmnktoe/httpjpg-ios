import SwiftUI
import Tokens
#if os(iOS)
import IntelligenceGlow
#endif

/// Glass panel with an intelligence sweep that can be switched off; it fades instead of vanishing.
struct CommandPaletteGlass<S: InsettableShape>: ViewModifier {
    let shape: S
    let isGlowing: Bool

    @Environment(\.pageTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // A wide blur and a short arc read as a halo rather than a spinning border on a panel this size.
    private static var sweepBlur: CGFloat { 45 }
    private static var sweepSpan: Double { 90 }
    private static var sweepOffset: Double { 220 }

    func body(content: Content) -> some View {
        glass(content)
            .background {
                ZStack {
                    if isGlowing {
                        sweep.transition(.opacity)
                    }
                }
                .animation(reduceMotion ? nil : Motion.glowFade, value: isGlowing)
            }
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
    private var sweep: some View {
        #if os(iOS)
        shape
            .fill(.clear)
            .intelligenceSweep(
                in: shape,
                blurRadius: Self.sweepBlur,
                sweepSpan: Self.sweepSpan,
                sweepOffset: Self.sweepOffset
            )
        #else
        EmptyView()
        #endif
    }
}

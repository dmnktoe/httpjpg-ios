import SwiftUI
import Tokens
#if os(iOS)
import BorderBeam
#endif

public extension View {
    /// A lime comet circling a rounded rect, drawn on top of the view; it fades in and out with `isActive`.
    ///
    /// The beam's corners are circular arcs, so the view's own shape should use `.circular` corners
    /// at the same radius or the line drifts off the edge in the corners.
    func beamOutline(cornerRadius: CGFloat, isActive: Bool) -> some View {
        modifier(BeamOutline(cornerRadius: cornerRadius, isActive: isActive))
    }
}

private struct BeamOutline: ViewModifier {
    let cornerRadius: CGFloat
    let isActive: Bool

    @Environment(\.pageTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // The library's 2.4 s lap reads as a loading spinner on a panel this wide; slower reads as a glint.
    private static let lap: TimeInterval = 3.2

    func body(content: Content) -> some View {
        #if os(iOS)
        content.borderBeam(
            shape: .rounded(cornerRadius),
            active: isActive,
            colors: BeamPalette.single(color),
            timing: BeamTiming(
                rotateDuration: Self.lap,
                fade: reduceMotion ? 0 : Motion.glowFadeDuration
            )
        )
        #else
        content
        #endif
    }

    // The site's selection lime. The light step washes out on a white page, so light pages take the deeper one.
    private var color: Color {
        theme.isDark ? Palette.accent.s400 : Palette.accent.s500
    }
}

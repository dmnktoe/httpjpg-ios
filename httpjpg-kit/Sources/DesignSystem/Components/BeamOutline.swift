import SwiftUI
import Tokens
#if os(iOS)
import BorderBeam
#endif

public extension View {
    /// A comet circling the view's edge, drawn on top of it; it fades in and out with `isActive`.
    ///
    /// The beam's corners are circular arcs, so the view's own shape should use `.circular` corners
    /// at the same radius or the line drifts off the edge in the corners.
    func beamOutline(
        _ style: BeamOutline.Style = .glint,
        cornerRadius: CGFloat,
        isActive: Bool
    ) -> some View {
        modifier(BeamOutline(style: style, cornerRadius: cornerRadius, isActive: isActive))
    }
}

public struct BeamOutline: ViewModifier {
    public enum Style: Sendable {
        /// One soft comet in the site's selection lime.
        case glint
        /// The loading screen's candy rainbow, circling the other way round.
        case rainbow
    }

    let style: Style
    let cornerRadius: CGFloat
    let isActive: Bool

    @Environment(\.pageTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // The library's 2.4 s lap reads as a loading spinner on a panel this wide; slower reads as a glint.
    private static let lap: TimeInterval = 3.2

    public func body(content: Content) -> some View {
        #if os(iOS)
        content.borderBeam(
            shape: .rounded(cornerRadius),
            direction: style == .rainbow ? .rightToLeft : .leftToRight,
            active: isActive,
            colors: colors,
            timing: BeamTiming(
                rotateDuration: Self.lap,
                fade: reduceMotion ? 0 : Motion.glowFadeDuration
            )
        )
        #else
        content
        #endif
    }

    #if os(iOS)
    private var colors: [Color] {
        switch style {
        // The light lime step washes out on a white page, so light pages take the deeper one.
        case .glint: return BeamPalette.single(theme.isDark ? Palette.accent.s400 : Palette.accent.s500)
        case .rainbow: return LoadingState.rainbow
        }
    }
    #endif
}

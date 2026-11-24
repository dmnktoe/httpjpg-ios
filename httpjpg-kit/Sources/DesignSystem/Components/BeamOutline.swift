import SwiftUI
import Tokens
#if os(iOS)
import BorderBeam
#endif

public extension View {
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
        case glint
        case rainbow
    }

    let style: Style
    let cornerRadius: CGFloat
    let isActive: Bool

    @Environment(\.pageTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        case .glint: return BeamPalette.single(theme.isDark ? Palette.accent.s400 : Palette.accent.s500)
        case .rainbow: return LoadingState.rainbow
        }
    }
    #endif
}

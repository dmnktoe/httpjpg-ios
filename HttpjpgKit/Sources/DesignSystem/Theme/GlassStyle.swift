import SwiftUI

/// Liquid Glass, applied only where it earns its keep.
///
/// The site's design language is brutalist — hard edges, flat fills, no depth.
/// Liquid Glass is the opposite. Rather than sand the design down to meet it,
/// the app splits the two: **chrome and controls float, content stays flat.**
/// The tab bar, buttons and the slideshow's arrows are glass; work cards,
/// headlines and rich text never are.
///
/// There used to be a setting to switch it off, and a flat chrome behind it.
/// Both are gone: two ways of drawing the same navigation is two things to keep
/// working, and the flat one was never the one anybody chose. What remains is
/// one behaviour with one honest fallback — `glassEffect` on iOS 26, and a
/// tinted `.ultraThinMaterial` below it.

public extension View {
    /// Fills the view's background with Liquid Glass in the given shape.
    ///
    /// - Parameters:
    ///   - shape: The glass outline.
    ///   - tint: Optional tint pulled through the material.
    ///   - interactive: Whether the glass reacts to touch. Only for things
    ///     that are actually tappable.
    func glassBackground(
        in shape: some Shape = .capsule,
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        modifier(GlassBackgroundModifier(shape: shape, tint: tint, isInteractive: interactive))
    }

}

private struct GlassBackgroundModifier<S: Shape>: ViewModifier {
    let shape: S
    let tint: Color?
    let isInteractive: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(glass, in: shape)
        } else {
            // Two layers, because `.ultraThinMaterial` has no tint of its own:
            // the wash sits in front of the blur, which is the closest iOS 17
            // gets to tinted glass. Without it a tinted control loses its
            // colour entirely on older systems.
            content
                .background(tint?.opacity(0.55) ?? .clear, in: shape)
                .background(.ultraThinMaterial, in: shape)
        }
    }

    @available(iOS 26.0, *)
    private var glass: Glass {
        var glass = Glass.regular
        if let tint {
            glass = glass.tint(tint)
        }
        return isInteractive ? glass.interactive() : glass
    }
}

/// Groups glass elements so they blend and morph into each other instead of
/// rendering as separate panes.
///
/// Wrap a row of glass controls in one of these; outside it, `glassMorphID`
/// does nothing and adjacent panels keep hard seams.
public struct GlassGroup<Content: View>: View {
    private let spacing: CGFloat?
    private let content: Content

    public init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content
            }
        } else {
            content
        }
    }
}

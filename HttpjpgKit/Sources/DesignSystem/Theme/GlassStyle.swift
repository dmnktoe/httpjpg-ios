import SwiftUI

/// Liquid Glass, applied only where it earns its keep.
///
/// The site's design language is brutalist — hard edges, flat fills, no depth.
/// Liquid Glass is the opposite. Rather than sand the design down to meet it,
/// the app splits the two: **chrome floats, content stays flat.** The masthead,
/// tab bar and detail bar are glass that content slides under; work cards,
/// headlines and rich text never are.
///
/// Everything here degrades in two steps:
///
/// 1. **iOS 26+, glass on** — real `glassEffect`, with morphing selection.
/// 2. **iOS 17–25, glass on** — `.ultraThinMaterial`, the closest older iOS has.
/// 3. **Glass off** — the flat `pageBg` surface plus a hairline rule, i.e. the
///    original brutalist chrome.
///
/// Step 3 is a user setting, not a fallback, which is what makes the split
/// above testable by eye instead of by argument.
private struct LiquidGlassEnabledKey: EnvironmentKey {
    static let defaultValue = true
}

public extension EnvironmentValues {
    /// Whether chrome renders as Liquid Glass. Read by ``GlassGroup`` and
    /// ``SwiftUI/View/glassBackground(in:tint:interactive:fallback:)``.
    var isLiquidGlassEnabled: Bool {
        get { self[LiquidGlassEnabledKey.self] }
        set { self[LiquidGlassEnabledKey.self] = newValue }
    }
}

/// `true` when the running OS can actually draw Liquid Glass.
///
/// Used for setting copy — the toggle should say what it will do, not promise
/// glass on a device that will render blur.
public var isLiquidGlassAvailable: Bool {
    if #available(iOS 26.0, *) { return true }
    return false
}

public extension View {
    /// Fills the view's background with Liquid Glass in the given shape.
    ///
    /// - Parameters:
    ///   - shape: The glass outline. Full-bleed chrome passes
    ///     `.rect(cornerRadius: 0)` — a sharp-cornered glass panel is the one
    ///     concession this design makes in the other direction.
    ///   - tint: Optional tint pulled through the material.
    ///   - interactive: Whether the glass reacts to touch. Only for things
    ///     that are actually tappable.
    ///   - fallback: The fill to use with glass switched off. Defaults to the
    ///     page background, which is right for chrome; a control whose colour
    ///     carries meaning — a button variant, a selected pill — passes its own
    ///     so it does not go colourless when the setting is off.
    func glassBackground(
        in shape: some Shape = .capsule,
        tint: Color? = nil,
        interactive: Bool = false,
        fallback: Color? = nil
    ) -> some View {
        modifier(GlassBackgroundModifier(
            shape: shape,
            tint: tint,
            isInteractive: interactive,
            fallback: fallback
        ))
    }

    /// Tags a view so Liquid Glass can morph it into its neighbours as it
    /// moves — the tab bar's selection pill travels rather than blinks.
    ///
    /// A no-op below iOS 26, and outside a ``GlassGroup``.
    @ViewBuilder
    func glassMorphID(_ id: some Hashable, in namespace: Namespace.ID) -> some View {
        if #available(iOS 26.0, *) {
            glassEffectID(id, in: namespace)
        } else {
            self
        }
    }
}

private struct GlassBackgroundModifier<S: Shape>: ViewModifier {
    let shape: S
    let tint: Color?
    let isInteractive: Bool
    let fallback: Color?

    @Environment(\.isLiquidGlassEnabled) private var isEnabled
    @Environment(\.pageTheme) private var theme

    func body(content: Content) -> some View {
        if isEnabled, #available(iOS 26.0, *) {
            content.glassEffect(glass, in: shape)
        } else if isEnabled {
            // Two layers, because `.ultraThinMaterial` has no tint of its own:
            // the wash sits in front of the blur, which is the closest iOS 17
            // gets to tinted glass. Without it a tinted control loses its
            // colour entirely on older systems.
            content
                .background(tint?.opacity(0.55) ?? .clear, in: shape)
                .background(.ultraThinMaterial, in: shape)
        } else {
            content.background(fallback ?? theme.background, in: shape)
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

    @Environment(\.isLiquidGlassEnabled) private var isEnabled

    public init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        if isEnabled, #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content
            }
        } else {
            content
        }
    }
}

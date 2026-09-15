import SwiftUI
import Tokens

public extension View {
    func glassBackground(
        in shape: some Shape = .capsule,
        tint: Color? = nil,
        interactive: Bool = false,
        clear: Bool = false
    ) -> some View {
        modifier(
            GlassBackgroundModifier(
                shape: shape,
                tint: tint,
                isInteractive: interactive,
                isClear: clear
            )
        )
    }
}

public extension View {
    func glassMorph(id: some Hashable, in namespace: Namespace.ID) -> some View {
        modifier(GlassMorphModifier(id: id, namespace: namespace))
    }
}

public extension View {
    func glassReveal(
        insertion: Animation = Motion.navigate,
        removal: Animation = Motion.stateChange
    ) -> some View {
        modifier(GlassRevealModifier(insertion: insertion, removal: removal))
    }
}

private struct GlassMorphModifier<ID: Hashable>: ViewModifier {
    let id: ID
    let namespace: Namespace.ID

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffectID(id, in: namespace)
        } else {
            content
        }
    }
}

private struct GlassRevealModifier: ViewModifier {
    let insertion: Animation
    let removal: Animation

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.transition(AsymmetricTransition(
                insertion: OpacityTransition().animation(insertion),
                removal: OpacityTransition().animation(removal)
            ))
        } else {
            content.transition(AsymmetricTransition(
                insertion: BlurReplaceTransition(configuration: .downUp).animation(insertion),
                removal: BlurReplaceTransition(configuration: .downUp).animation(removal)
            ))
        }
    }
}

private struct ChromeHeldKey: EnvironmentKey {
    static let defaultValue = false
}

public extension EnvironmentValues {
    var chromeHeld: Bool {
        get { self[ChromeHeldKey.self] }
        set { self[ChromeHeldKey.self] = newValue }
    }
}

private struct GlassBackgroundModifier<S: Shape>: ViewModifier {
    let shape: S
    let tint: Color?
    let isInteractive: Bool
    let isClear: Bool

    @Environment(\.chromeHeld) private var isHeld
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.pageTheme) private var theme

    func body(content: Content) -> some View {
        let glassed: some View = Group {
            if isHeld || reduceTransparency {
                content.background(flatFill, in: shape)
            } else if #available(iOS 26.0, *) {
                content.glassEffect(glass, in: shape)
            } else if let tint {
                content
                    .background(tint.opacity(0.55), in: shape)
                    .background(.ultraThinMaterial, in: shape)
            } else {
                content
            }
        }

        // Interactive glass draws its touch highlight from the view bounds, which
        // defaults to a rounded rect on small square frames — clip to the declared
        // shape so press-and-drag stays circular.
        if isInteractive {
            glassed.clipShape(shape)
        } else {
            glassed
        }
    }

    private var flatFill: Color {
        (tint ?? theme.chromeFill).opacity(reduceTransparency ? 0.94 : 0.55)
    }

    @available(iOS 26.0, *)
    private var glass: Glass {
        let material = tint.map { base.tint($0) } ?? base
        guard isInteractive else { return material }
        if tint != nil || isClear { return material.interactive() }
        if #available(iOS 27.0, *) { return material.interactive() }
        return material
    }

    @available(iOS 26.0, *)
    private var base: Glass {
        if isClear {
            return .clear
        }
        if #available(iOS 27.0, *) {
            // iOS 27's readability pass makes untinted regular glass usable on
            // light pages; iOS 26 still painted a grey disc, so that stays identity.
            return .regular
        }
        return tint == nil ? .identity : .regular
    }
}

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

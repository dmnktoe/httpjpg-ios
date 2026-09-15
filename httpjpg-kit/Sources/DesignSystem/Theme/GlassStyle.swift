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
            GlassSurface(
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
        modifier(GlassMorph(id: id, namespace: namespace))
    }
}

public extension View {
    func glassReveal(
        insertion: Animation = Motion.navigate,
        removal: Animation = Motion.stateChange
    ) -> some View {
        modifier(GlassReveal(insertion: insertion, removal: removal))
    }
}

private struct GlassSurface<S: Shape>: ViewModifier {
    let shape: S
    let tint: Color?
    let isInteractive: Bool
    let isClear: Bool

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.pageTheme) private var theme

    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(fill, in: shape)
        } else if #available(iOS 26.0, *) {
            let surface = content.glassEffect(material, in: shape)
            if isInteractive {
                surface.clipShape(shape)
            } else {
                surface
            }
        } else if let tint {
            content
                .background(tint.opacity(0.55), in: shape)
                .background(.ultraThinMaterial, in: shape)
        } else {
            content
        }
    }

    private var fill: Color {
        (tint ?? theme.chromeFill).opacity(0.94)
    }

    @available(iOS 26.0, *)
    private var material: Glass {
        let base: Glass
        if isClear {
            base = .clear
        } else if tint != nil {
            base = .regular
        } else if #available(iOS 27.0, *) {
            base = .regular
        } else {
            base = .identity
        }
        var glass = tint.map { base.tint($0) } ?? base
        if isInteractive {
            glass = glass.interactive()
        }
        return glass
    }
}

private struct GlassMorph<ID: Hashable>: ViewModifier {
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

private struct GlassReveal: ViewModifier {
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

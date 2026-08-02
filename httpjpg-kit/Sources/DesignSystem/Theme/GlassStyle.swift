import SwiftUI

public extension View {
    func glassBackground(
        in shape: some Shape = .capsule,
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        modifier(GlassBackgroundModifier(shape: shape, tint: tint, isInteractive: interactive))
    }
}

/// Tags a glass shape so the container can morph it into its neighbours as it
/// appears and disappears, instead of cross-fading it in place. Only does
/// anything inside a `GlassGroup` sharing the same namespace.
public extension View {
    func glassMorph(id: some Hashable, in namespace: Namespace.ID) -> some View {
        modifier(GlassMorphModifier(id: id, namespace: namespace))
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

private struct GlassBackgroundModifier<S: Shape>: ViewModifier {
    let shape: S
    let tint: Color?
    let isInteractive: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(glass, in: shape)
        } else {
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

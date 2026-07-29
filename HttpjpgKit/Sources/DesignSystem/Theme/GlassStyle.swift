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

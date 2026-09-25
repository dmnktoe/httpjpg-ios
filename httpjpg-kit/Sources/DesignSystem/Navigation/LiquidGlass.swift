import SwiftUI

public enum LiquidGlass {
    static let materialTintOpacity: Double = 0.55
}

public extension View {
    func liquidGlass(
        in shape: some Shape = .capsule,
        tint: Color? = nil,
        isInteractive: Bool = false,
        isOpaque: Bool = false
    ) -> some View {
        modifier(LiquidGlassSurface(
            shape: shape,
            tint: tint,
            isInteractive: isInteractive,
            isOpaque: isOpaque
        ))
    }

    func liquidGlassID(_ id: some Hashable, in namespace: Namespace.ID) -> some View {
        modifier(LiquidGlassIdentity(id: id, namespace: namespace))
    }

    @ViewBuilder
    // A distinct label avoids overload ambiguity with liquidGlassID(_:in:).
    func liquidGlassID(ifPresent id: AnyHashable?, in namespace: Namespace.ID?) -> some View {
        if let id, let namespace {
            liquidGlassID(id, in: namespace)
        } else {
            self
        }
    }
}

private struct LiquidGlassSurface<S: Shape>: ViewModifier {
    let shape: S
    let tint: Color?
    let isInteractive: Bool
    let isOpaque: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if isInteractive {
            // Interactive glass derives a rectangular highlight from small square view bounds.
            surface(content).clipShape(shape)
        } else {
            surface(content)
        }
    }

    @ViewBuilder
    private func surface(_ content: Content) -> some View {
        if let tint, isOpaque {
            // Glass renders behind content, so an opaque foreground fill would hide its highlights.
            content.background(tint, in: shape)
        } else if #available(iOS 26.0, *) {
            content.glassEffect(glass, in: shape)
        } else if let tint {
            content
                .background(tint.opacity(LiquidGlass.materialTintOpacity), in: shape)
                .background(.ultraThinMaterial, in: shape)
        } else {
            content.background(.ultraThinMaterial, in: shape)
        }
    }

    @available(iOS 26.0, *)
    private var glass: Glass {
        let base: Glass = {
            guard let tint else { return .regular }
            return Glass.regular.tint(tint)
        }()
        return isInteractive ? base.interactive() : base
    }
}

private struct LiquidGlassIdentity<ID: Hashable>: ViewModifier {
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

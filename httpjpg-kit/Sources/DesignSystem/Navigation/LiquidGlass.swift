import SwiftUI

/// The one place in the package that names a Liquid Glass symbol.
///
/// Callers ask for `.liquidGlass(in:tint:)` and get the best surface the running
/// OS can draw: real glass on iOS 26+, a tinted material below it.
public enum LiquidGlass {
    /// Tint strength on iOS 17–25, where `.ultraThinMaterial` is still doing
    /// most of the work underneath.
    static let materialTintOpacity: Double = 0.55
}

public extension View {
    /// Paints a Liquid Glass surface behind this view.
    ///
    /// - Parameters:
    ///   - shape: the surface outline; also the hit and highlight shape.
    ///   - tint: the colour the glass takes. `nil` asks for untinted system
    ///     glass — the same backing the toolbar hamburger uses.
    ///   - isInteractive: adds the press-and-drag highlight for controls.
    ///   - isOpaque: fills the shape with the tint outright instead of glassing
    ///     it. Selected pills ask for this so they read as `.glassProminent`
    ///     against idle clear glass.
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

    /// Joins this surface to a morph identity. Sibling surfaces sharing a
    /// `LiquidGlassContainer` melt into one another instead of cross-fading.
    func liquidGlassID(_ id: some Hashable, in namespace: Namespace.ID) -> some View {
        modifier(LiquidGlassIdentity(id: id, namespace: namespace))
    }

    /// `liquidGlassID` for a shape that may or may not want to morph. Carries
    /// its own label so it cannot overload against the form it calls.
    @ViewBuilder
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
            // Interactive glass derives its highlight from the view bounds, which
            // rounds to a rect on small square frames — clipping keeps an orb round.
            surface(content).clipShape(shape)
        } else {
            surface(content)
        }
    }

    @ViewBuilder
    private func surface(_ content: Content) -> some View {
        if let tint, isOpaque {
            // Flat, and not a layer of glass with a solid fill in front of it:
            // glass always renders *behind* what it backs, so an opaque fill
            // would bury its highlights and cost a blur pass for nothing.
            content.background(tint, in: shape)
        } else if #available(iOS 26.0, *) {
            content.glassEffect(glass, in: shape)
        } else if let tint {
            content
                .background(tint.opacity(LiquidGlass.materialTintOpacity), in: shape)
                .background(.ultraThinMaterial, in: shape)
        } else {
            // Untinted fallback for pre-glass OS: frosted material without a
            // chrome wash, close to the clear system glass idle pills use.
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

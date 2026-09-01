import SwiftUI
import Tokens

public extension View {
    func glassBackground(
        in shape: some Shape = .capsule,
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        modifier(GlassBackgroundModifier(shape: shape, tint: tint, isInteractive: interactive))
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

    @Environment(\.chromeHeld) private var isHeld

    func body(content: Content) -> some View {
        let glassed: some View = Group {
            if #available(iOS 26.0, *) {
                content
                    .background(heldFill, in: shape)
                    .glassEffect(glass, in: shape)
                    // Flatten instantly on hold so a live material does not
                    // re-blur during the drawer drag; materialize on release
                    // so the glass shadow does not slam back in.
                    .glassEffectTransition(isHeld ? .identity : .materialize)
            } else if isHeld {
                content.background(heldFill, in: shape)
            } else if let tint {
                content
                    .background(tint.opacity(0.55), in: shape)
                    .background(.ultraThinMaterial, in: shape)
            } else {
                // No CMS / caller tint: skip the frosted material so we don't
                // leave a grey disc on light pages.
                content
            }
        }

        // Interactive glass draws its touch highlight from the view bounds, which
        // defaults to a rounded rect on small square frames — clip to the declared
        // shape so press-and-drag stays circular (see GlassPill).
        Group {
            if isInteractive {
                glassed.clipShape(shape)
            } else {
                glassed
            }
        }
        // Opening shares the drawer spring with `isOpen`. Kill that
        // interpolation on the way in so glass drops out in one frame
        // (and the drag stays at 60fps). Leave the way out animated so
        // `.materialize` can fade the shadow back.
        .transaction(value: isHeld) { transaction in
            guard isHeld else { return }
            transaction.animation = nil
        }
    }

    private var heldFill: Color {
        isHeld ? (tint ?? Color.clear) : Color.clear
    }

    @available(iOS 26.0, *)
    private var glass: Glass {
        // Identity (not an unmount) while the drawer is in flight: a moving
        // backdrop made live glass re-blur every frame, and tearing the
        // modifier out made selected pills rematerialize as a hollow stroke
        // that filled in a beat after the page settled.
        guard !isHeld, let tint else {
            // Untinted regular glass still reads as a grey fill on white.
            return .identity
        }
        let tinted = Glass.regular.tint(tint)
        return isInteractive ? tinted.interactive() : tinted
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

import SwiftUI
import Tokens

public extension View {
    func glassBackground(
        in shape: some Shape = .capsule,
        tint: Color? = nil,
        interactive: Bool = false,
        asciiUnderlay: Bool = true
    ) -> some View {
        modifier(GlassBackgroundModifier(
            shape: shape,
            tint: tint,
            isInteractive: interactive,
            asciiUnderlay: asciiUnderlay
        ))
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
    let asciiUnderlay: Bool

    @Environment(\.chromeHeld) private var isHeld
    @Environment(\.pageTheme) private var theme
    @Environment(\.chromeAccent) private var accent

    func body(content: Content) -> some View {
        let fill = resolvedTint
        if isHeld {
            content
                .background { underlay }
                .background(fill, in: shape)
        } else if #available(iOS 26.0, *) {
            content
                .background { underlay }
                .glassEffect(glass(fill), in: shape)
        } else {
            content
                .background { underlay }
                .background(fill.opacity(0.55), in: shape)
                .background(.ultraThinMaterial, in: shape)
        }
    }

    private var resolvedTint: Color {
        if let tint { return tint }
        return theme.chromeFill(accent: accent)
    }

    @ViewBuilder
    private var underlay: some View {
        if asciiUnderlay {
            Text(Ascii.sparkles)
                .font(Typography.mono(Typography.Size.xxs))
                .foregroundStyle(theme.foreground.opacity(0.14))
                .lineLimit(1)
                .minimumScaleFactor(0.2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .clipShape(shape)
        }
    }

    @available(iOS 26.0, *)
    private func glass(_ fill: Color) -> Glass {
        var glass = Glass.regular.tint(fill)
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

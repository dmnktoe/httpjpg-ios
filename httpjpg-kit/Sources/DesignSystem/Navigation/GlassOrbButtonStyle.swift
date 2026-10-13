import SwiftUI
import Tokens

public struct GlassOrbButtonStyle: ButtonStyle {
    private let tint: PillTint
    private let diameter: CGFloat
    private let morphID: AnyHashable?
    private let namespace: Namespace.ID?

    public init(
        tint: PillTint,
        diameter: CGFloat = PillMetrics.orbDiameter,
        morphID: AnyHashable? = nil,
        in namespace: Namespace.ID? = nil
    ) {
        self.tint = tint
        self.diameter = diameter
        self.morphID = morphID
        self.namespace = namespace
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: Typography.Size.md, weight: .semibold))
            .foregroundStyle(tint.label)
            .frame(width: diameter, height: diameter)
            .contentShape(.circle)
            .liquidGlass(in: .circle, tint: tint.fill, isInteractive: true, isOpaque: tint.isOpaque)
            .overlay {
                if let stroke = tint.stroke {
                    Circle().strokeBorder(stroke, lineWidth: PillMetrics.hairline)
                }
            }
            .liquidGlassID(ifPresent: morphID, in: namespace)
            .scaleEffect(configuration.isPressed ? PillMetrics.pressedScale : 1)
            .animation(Motion.pressed, value: configuration.isPressed)
            .animation(Motion.stateChange, value: tint)
    }
}

public extension ButtonStyle where Self == GlassOrbButtonStyle {
    static func glassOrb(
        _ tint: PillTint,
        diameter: CGFloat = PillMetrics.orbDiameter,
        morphID: AnyHashable? = nil,
        in namespace: Namespace.ID? = nil
    ) -> GlassOrbButtonStyle {
        GlassOrbButtonStyle(tint: tint, diameter: diameter, morphID: morphID, in: namespace)
    }
}

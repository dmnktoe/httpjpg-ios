import SwiftUI
import Tokens

/// A capsule of Liquid Glass around a text label.
///
/// Idle pills are untinted system glass (hamburger); selected pills are tinted
/// glass so they stay in the shared glass container. Written as a `ButtonStyle`
/// so every pill in the app — tab bar, work filter, variant picker, the reset
/// button in info — gets the press state, the hit shape and the accessibility
/// traits from SwiftUI instead of restating them.
public struct GlassPillButtonStyle: ButtonStyle {
    public enum Size: Sendable {
        case regular
        case compact

        var horizontalPadding: CGFloat {
            switch self {
            case .regular: return PillMetrics.horizontalPadding
            case .compact: return PillMetrics.compactHorizontalPadding
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .regular: return PillMetrics.verticalPadding
            case .compact: return PillMetrics.compactVerticalPadding
            }
        }
    }

    private let tint: PillTint
    private let size: Size
    private let morphID: AnyHashable?
    private let namespace: Namespace.ID?

    public init(
        tint: PillTint,
        size: Size = .regular,
        morphID: AnyHashable? = nil,
        in namespace: Namespace.ID? = nil
    ) {
        self.tint = tint
        self.size = size
        self.morphID = morphID
        self.namespace = namespace
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .lineLimit(1)
            .minimumScaleFactor(PillMetrics.labelScaleFloor)
            .frame(height: PillMetrics.labelHeight)
            .foregroundStyle(tint.label)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .contentShape(.capsule)
            .liquidGlass(in: .capsule, tint: tint.fill, isInteractive: true, isOpaque: tint.isOpaque)
            .overlay {
                if let stroke = tint.stroke {
                    Capsule().strokeBorder(stroke, lineWidth: PillMetrics.hairline)
                }
            }
            .liquidGlassID(ifPresent: morphID, in: namespace)
            .scaleEffect(configuration.isPressed ? PillMetrics.pressedScale : 1)
            .animation(Motion.pressed, value: configuration.isPressed)
            .animation(Motion.stateChange, value: tint)
    }
}

public extension ButtonStyle where Self == GlassPillButtonStyle {
    static func glassPill(
        _ tint: PillTint,
        size: GlassPillButtonStyle.Size = .regular,
        morphID: AnyHashable? = nil,
        in namespace: Namespace.ID? = nil
    ) -> GlassPillButtonStyle {
        GlassPillButtonStyle(tint: tint, size: size, morphID: morphID, in: namespace)
    }
}

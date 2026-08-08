import SwiftUI

public struct BrutalButtonStyle: ButtonStyle {
    public enum Variant: String, Sendable, CaseIterable {
        case primary
        case secondary
        case accent
        case danger

        public var fill: Color {
            switch self {
            case .primary: return Palette.primary.s500
            case .secondary: return Palette.neutral.s300
            case .accent: return Palette.accent.s400
            case .danger: return Palette.danger.s500
            }
        }

        public var label: Color {
            switch self {
            case .primary, .danger: return Palette.white
            case .secondary, .accent: return Palette.black
            }
        }
    }

    public enum Size: String, Sendable, CaseIterable {
        case sm
        case md
        case lg

        var font: CGFloat {
            switch self {
            case .sm: return Typography.Size.sm
            case .md: return Typography.Size.md
            case .lg: return Typography.Size.base
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .sm: return Spacing.s4
            case .md: return Spacing.s5
            case .lg: return Spacing.s6
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .sm: return Spacing.s2
            case .md: return Spacing.s3
            case .lg: return Spacing.s4
            }
        }
    }

    private let variant: Variant
    private let size: Size

    public init(variant: Variant = .primary, size: Size = .md) {
        self.variant = variant
        self.size = size
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label

            .font(Typography.sansBold(size.font))
            .foregroundStyle(variant.label)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .glassBackground(
                in: .capsule,
                tint: variant.fill.opacity(configuration.isPressed ? 1 : 0.9),
                interactive: true
            )
            .shadow(color: variant.fill.opacity(0.3), radius: 10)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.pressed, value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == BrutalButtonStyle {
    static func brutal(
        variant: BrutalButtonStyle.Variant = .primary,
        size: BrutalButtonStyle.Size = .md
    ) -> BrutalButtonStyle {
        BrutalButtonStyle(variant: variant, size: size)
    }
}

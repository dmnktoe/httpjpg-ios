import SwiftUI

/// Pill button — the Swift port of the `button` Panda recipe.
///
/// The web draws its fill on a blurred `::before` pseudo-element to get the
/// soft glow; iOS gets the same read from a tinted shadow under a solid pill.
public struct BrutalButtonStyle: ButtonStyle {
    public enum Variant: String, Sendable, CaseIterable {
        case primary
        case secondary
        case accent
        case danger

        /// Public because the tab bar's selection pill tints itself from the
        /// same table — one definition of what "secondary" looks like.
        public var fill: Color {
            switch self {
            case .primary: return Palette.primary.s500
            case .secondary: return Palette.neutral.s300
            case .accent: return Palette.accent.s400
            case .danger: return Palette.danger.s500
            }
        }

        /// The text colour that stays legible on ``fill``.
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

    /// The pill is Liquid Glass tinted by the variant rather than a solid fill.
    /// `interactive: true` is what makes it flex under a finger — a button is
    /// exactly the kind of control that behaviour was written for. With glass
    /// switched off it falls back to the variant's own colour, so the button
    /// still reads as primary or danger.
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.sans(size.font).weight(.medium))
            .foregroundStyle(variant.label)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .glassBackground(
                in: .capsule,
                tint: variant.fill.opacity(configuration.isPressed ? 1 : 0.9),
                interactive: true,
                fallback: variant.fill.opacity(configuration.isPressed ? 1 : 0.9)
            )
            .shadow(color: variant.fill.opacity(0.3), radius: 10)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
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

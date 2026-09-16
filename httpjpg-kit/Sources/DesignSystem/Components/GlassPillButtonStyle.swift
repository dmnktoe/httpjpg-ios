import SwiftUI
import Tokens

/// The one capsule recipe behind every pill control: the bottom tab bar, the
/// work variant tabs, the tag filter, the cache button. Callers bring the label
/// and its font, the style brings the metrics, the glass and the selected state,
/// so a selected pill looks the same wherever it sits.
///
/// Press feedback is a scale. An opacity or a colour filter would push the pill
/// through an offscreen pass and the glass inside would lose the live backdrop
/// it samples.
public struct GlassPillButtonStyle: ButtonStyle {
    public enum Size: Sendable {
        case regular
        case compact

        var horizontalPadding: CGFloat {
            switch self {
            case .regular: return Spacing.s4
            case .compact: return Spacing.s3
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .regular: return Spacing.s3
            case .compact: return Spacing.s2
            }
        }
    }

    private let isSelected: Bool
    private let size: Size
    private let morphID: AnyHashable?
    private let namespace: Namespace.ID?

    public init(
        isSelected: Bool = false,
        size: Size = .regular,
        morphID: AnyHashable? = nil,
        in namespace: Namespace.ID? = nil
    ) {
        self.isSelected = isSelected
        self.size = size
        self.morphID = morphID
        self.namespace = namespace
    }

    public func makeBody(configuration: Configuration) -> some View {
        // A ButtonStyle is not a view, so it never sees environment updates.
        // The pill body has to be one.
        Pill(
            configuration: configuration,
            isSelected: isSelected,
            size: size,
            morphID: morphID,
            namespace: namespace
        )
    }

    private struct Pill: View {
        private static let pressedScale: CGFloat = 0.96

        let configuration: ButtonStyleConfiguration
        let isSelected: Bool
        let size: Size
        let morphID: AnyHashable?
        let namespace: Namespace.ID?

        @Environment(\.pageTheme) private var theme
        @Environment(\.chromeAccent) private var accent
        @Environment(\.chromeOnAccent) private var onAccent

        var body: some View {
            morphed(
                configuration.label
                    .foregroundStyle(labelColor)
                    .padding(.horizontal, size.horizontalPadding)
                    .padding(.vertical, size.verticalPadding)
                    .contentShape(.capsule)
                    .glassBackground(in: .capsule, tint: fill, interactive: true)
            )
            .clipShape(.capsule)
            .overlay {
                if let stroke {
                    Capsule().strokeBorder(stroke, lineWidth: 1)
                }
            }
            .scaleEffect(configuration.isPressed ? Self.pressedScale : 1)
            .animation(Motion.pressed, value: configuration.isPressed)
        }

        @ViewBuilder
        private func morphed(_ view: some View) -> some View {
            if let morphID, let namespace {
                view.glassMorph(id: morphID, in: namespace)
            } else {
                view
            }
        }

        private var fill: Color {
            isSelected
                ? theme.chromeActiveFill(accent: accent)
                : theme.chromeFill(accent: accent)
        }

        private var labelColor: Color {
            isSelected
                ? theme.chromeActiveLabel
                : theme.chromeLabel(onAccent: onAccent)
        }

        /// Only the selected pill carries a hairline. Ringing the resting ones
        /// too would draw every capsule back out of the glass the container
        /// merges them into.
        private var stroke: Color? {
            isSelected ? theme.chromeActiveStroke(accent: accent) : nil
        }
    }
}

public extension ButtonStyle where Self == GlassPillButtonStyle {
    static func glassPill(
        isSelected: Bool = false,
        size: GlassPillButtonStyle.Size = .regular,
        morphID: AnyHashable? = nil,
        in namespace: Namespace.ID? = nil
    ) -> GlassPillButtonStyle {
        GlassPillButtonStyle(isSelected: isSelected, size: size, morphID: morphID, in: namespace)
    }
}

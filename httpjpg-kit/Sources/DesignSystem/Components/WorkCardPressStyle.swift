import SwiftUI
import Tokens

/// Press overlay: a short glass capsule with title + meta over the card media.
public struct WorkCardPressStyle: ButtonStyle {
    private let title: String
    private let meta: String?

    @Environment(\.pageTheme) private var theme
    @Environment(\.chromeAccent) private var accent
    @Environment(\.chromeOnAccent) private var onAccent

    public init(title: String, meta: String? = nil) {
        self.title = title
        self.meta = meta
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay(alignment: .bottomLeading) {
                if configuration.isPressed {
                    capsule
                        .padding(Spacing.s3)
                        .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .bottomLeading)))
                }
            }
            .animation(Motion.pressed, value: configuration.isPressed)
    }

    private var capsule: some View {
        HStack(spacing: Spacing.s2) {
            Text(title)
                .font(Typography.mono(Typography.Size.xs))
                .lineLimit(1)
            if let meta, !meta.isEmpty {
                Text("·")
                    .opacity(Opacities.subtle)
                Text(meta)
                    .font(Typography.mono(Typography.Size.xs))
                    .opacity(Opacities.muted)
                    .lineLimit(1)
            }
        }
        .foregroundStyle(theme.chromeLabel(onAccent: onAccent))
        .padding(.horizontal, Spacing.s3)
        .padding(.vertical, Spacing.s2)
        .glassBackground(in: .capsule, tint: theme.chromeFill(accent: accent), interactive: true)
        .overlay(Capsule().stroke(theme.chromeStroke(accent: accent), lineWidth: 1))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

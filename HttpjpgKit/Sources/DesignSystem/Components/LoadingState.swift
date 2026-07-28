import SwiftUI

/// Full-bleed placeholder shown while a screen's first payload is in flight.
public struct LoadingState: View {
    private let label: String

    public init(label: String = "loading") {
        self.label = label
    }

    public var body: some View {
        VStack(spacing: Spacing.s4) {
            RainbowBar()
                .frame(width: 160)
            MonoText(
                label,
                size: Typography.Size.sm,
                tracking: Typography.Size.sm * 0.1,
                opacity: Opacities.subtle
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading \(label)")
    }
}

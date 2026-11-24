import SwiftUI
import Tokens

public struct LoadingState: View {
    // Closed with its first color again, so the sliding gradient loops without a seam.
    private static let rainbow = Palette.rainbow + Palette.rainbow.prefix(1)

    private static let doubledRainbow: [Color] = rainbow + rainbow.dropFirst()

    private let label: String

    @State private var isSliding = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(label: String = "Loading...") {
        self.label = label
    }

    public var body: some View {
        VStack(spacing: Spacing.s2) {
            Text(label)
                .font(Typography.sans(Typography.Size.sm))
                .tracking(Typography.Size.sm * 0.05)
                .foregroundStyle(gradient)

            Text("▰▰▰▱▱▱▰▰▰▱▱▱")
                .font(Typography.mono(Typography.Size.xs))
                .tracking(Typography.Size.xs * 0.2)
                .opacity(Opacities.muted)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading \(label)")
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                isSliding = true
            }
        }
    }

    private var gradient: LinearGradient {
        LinearGradient(
            colors: Self.doubledRainbow,
            startPoint: UnitPoint(x: isSliding ? 0 : -1, y: 0.5),
            endPoint: UnitPoint(x: isSliding ? 2 : 1, y: 0.5)
        )
    }
}

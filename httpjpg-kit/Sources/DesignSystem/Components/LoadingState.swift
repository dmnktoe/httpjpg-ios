import SwiftUI
import Tokens

public struct LoadingState: View {
    private static let rainbow: [Color] = [
        Color(red: 0xF7 / 255, green: 0x25 / 255, blue: 0x85 / 255),
        Color(red: 0xFF / 255, green: 0x00 / 255, blue: 0x6E / 255),
        Color(red: 0xFE / 255, green: 0xE4 / 255, blue: 0x40 / 255),
        Color(red: 0x00 / 255, green: 0xF5 / 255, blue: 0xD4 / 255),
        Color(red: 0x00 / 255, green: 0xBB / 255, blue: 0xF9 / 255),
        Color(red: 0x9B / 255, green: 0x5D / 255, blue: 0xE5 / 255),
        Color(red: 0xF7 / 255, green: 0x25 / 255, blue: 0x85 / 255),
    ]

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

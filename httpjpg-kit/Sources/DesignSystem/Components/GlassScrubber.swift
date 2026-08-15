import SwiftUI
import Tokens

public struct GlassScrubber: View {
    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let tint: Color
    private let onEditingChanged: (Bool) -> Void

    @Environment(\.pageTheme) private var theme
    @Environment(\.chromeAccent) private var accent

    public init(
        value: Binding<Double>,
        in range: ClosedRange<Double> = 0 ... 1,
        tint: Color? = nil,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        _value = value
        self.range = range
        self.tint = tint ?? Palette.accent.s400
        self.onEditingChanged = onEditingChanged
    }

    public var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let progress = CGFloat(normalized)

            Capsule()
                .fill(Color.clear)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .glassBackground(in: .capsule, tint: theme.chromeFill(accent: accent), interactive: true)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(tint.opacity(0.9))
                        .frame(width: max(Spacing.s3, width * progress))
                        .padding(2)
                }
                .overlay {
                    Capsule().stroke(theme.chromeStroke(accent: accent), lineWidth: 1)
                }
                .contentShape(Capsule())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            onEditingChanged(true)
                            let ratio = min(1, max(0, drag.location.x / width))
                            value = range.lowerBound + (range.upperBound - range.lowerBound) * Double(ratio)
                        }
                        .onEnded { _ in onEditingChanged(false) }
                )
        }
        .frame(height: Spacing.s5)
        .accessibilityValue(Text("\(Int((normalized * 100).rounded())) percent"))
        .accessibilityAdjustableAction { direction in
            let span = range.upperBound - range.lowerBound
            let step = span * 0.05
            switch direction {
            case .increment: value = min(range.upperBound, value + step)
            case .decrement: value = max(range.lowerBound, value - step)
            @unknown default: break
            }
        }
    }

    private var normalized: Double {
        let span = max(range.upperBound - range.lowerBound, .leastNonzeroMagnitude)
        return min(1, max(0, (value - range.lowerBound) / span))
    }
}

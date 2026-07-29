import MarqueeLabel
import SwiftUI
import UIKit

public struct Marquee: View {
    public enum Speed: Sendable {
        case rate(CGFloat)

        case secondsPerCopy(CGFloat)
    }

    public enum Direction: String, Sendable {
        case left
        case right
    }

    private let text: String
    private let font: UIFont
    private let speed: Speed
    private let direction: Direction
    private let repeatCount: Int
    private let fadeLength: CGFloat
    private let trailingBuffer: CGFloat

    private let color: Color?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.pageTheme) private var theme

    public init(
        _ text: String,
        font: UIFont = Typography.uiMono(Typography.Size.sm),
        speed: Speed = .rate(30),
        direction: Direction = .left,
        repeatCount: Int = 3,
        fadeLength: CGFloat = 12,
        trailingBuffer: CGFloat = 32,
        color: Color? = nil
    ) {
        self.text = text
        self.font = font
        self.speed = speed
        self.direction = direction
        self.repeatCount = max(repeatCount, 1)
        self.fadeLength = fadeLength
        self.trailingBuffer = trailingBuffer
        self.color = color
    }

    public var body: some View {
        MarqueeLabelView(
            text: String(repeating: text, count: repeatCount),
            font: font,
            color: UIColor(color ?? theme.foreground),
            rate: resolvedRate,
            isReversed: direction == .right,
            fadeLength: fadeLength,
            trailingBuffer: trailingBuffer,
            isLabelized: reduceMotion
        )
        .frame(height: font.lineHeight)
        .accessibilityElement()
        .accessibilityLabel(text)
    }

    private var resolvedRate: CGFloat {
        switch speed {
        case .rate(let value):
            return max(value, 1)
        case .secondsPerCopy(let seconds):
            let width = (text as NSString).size(withAttributes: [.font: font]).width
            return max(width / max(seconds, 0.1), 10)
        }
    }
}

private struct MarqueeLabelView: UIViewRepresentable {
    let text: String
    let font: UIFont
    let color: UIColor
    let rate: CGFloat
    let isReversed: Bool
    let fadeLength: CGFloat
    let trailingBuffer: CGFloat
    let isLabelized: Bool

    func makeUIView(context: Context) -> MarqueeLabel {
        let label = MarqueeLabel(frame: .zero, rate: rate, fadeLength: fadeLength)
        label.animationCurve = .linear
        label.animationDelay = 0
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        apply(to: label)
        return label
    }

    func updateUIView(_ label: MarqueeLabel, context: Context) {
        apply(to: label)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: MarqueeLabel, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 0, height: font.lineHeight)
    }

    private func apply(to label: MarqueeLabel) {
        label.type = isReversed ? .continuousReverse : .continuous
        label.text = text
        label.font = font
        label.textColor = color
        label.speed = .rate(rate)
        label.fadeLength = fadeLength
        label.trailingBuffer = trailingBuffer

        label.labelize = isLabelized
    }
}

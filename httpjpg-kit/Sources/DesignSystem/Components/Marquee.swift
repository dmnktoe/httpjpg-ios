import MarqueeLabel
import SwiftUI
import UIKit

private struct MarqueeHeldKey: EnvironmentKey {
    static let defaultValue = false
}

public extension EnvironmentValues {
    /// Set by an ancestor (e.g. a drag gesture) to freeze every marquee beneath it at its
    /// home position instead of scrolling — MarqueeLabel restarts from scratch on every
    /// layout pass, so continuous interactive layout changes (a swipe) would otherwise make
    /// it look like the scroll keeps restarting.
    var marqueeHeld: Bool {
        get { self[MarqueeHeldKey.self] }
        set { self[MarqueeHeldKey.self] = newValue }
    }
}

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
    private let pauseDuration: CGFloat

    private let color: Color?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.pageTheme) private var theme
    @Environment(\.marqueeHeld) private var isHeld

    public init(
        _ text: String,
        font: UIFont = Typography.uiMono(Typography.Size.sm),
        speed: Speed = .rate(30),
        direction: Direction = .left,
        repeatCount: Int = 3,
        fadeLength: CGFloat = 12,
        trailingBuffer: CGFloat = 32,
        pauseDuration: CGFloat = 0,
        color: Color? = nil
    ) {
        self.text = text
        self.font = font
        self.speed = speed
        self.direction = direction
        self.repeatCount = max(repeatCount, 1)
        self.fadeLength = fadeLength
        self.trailingBuffer = trailingBuffer
        self.pauseDuration = pauseDuration
        self.color = color
    }

    public var body: some View {
        MarqueeLabelView(
            text: String(repeating: text, count: repeatCount),
            font: font,
            color: color ?? theme.foreground,
            rate: resolvedRate,
            isReversed: direction == .right,
            fadeLength: fadeLength,
            trailingBuffer: trailingBuffer,
            pauseDuration: pauseDuration,
            isLabelized: reduceMotion,
            isHeld: isHeld
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
    let color: Color
    let rate: CGFloat
    let isReversed: Bool
    let fadeLength: CGFloat
    let trailingBuffer: CGFloat
    let pauseDuration: CGFloat
    let isLabelized: Bool
    let isHeld: Bool

    struct Settings: Equatable {
        let text: String
        let font: UIFont
        let color: Color
        let rate: CGFloat
        let isReversed: Bool
        let fadeLength: CGFloat
        let trailingBuffer: CGFloat
        let pauseDuration: CGFloat
        let isLabelized: Bool
        let isHeld: Bool
    }

    final class Coordinator {
        var applied: Settings?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MarqueeLabel {
        let label = MarqueeLabel(frame: .zero, rate: rate, fadeLength: fadeLength)
        label.animationCurve = .linear
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        apply(to: label, coordinator: context.coordinator)
        return label
    }

    func updateUIView(_ label: MarqueeLabel, context: Context) {
        apply(to: label, coordinator: context.coordinator)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: MarqueeLabel, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 0, height: font.lineHeight)
    }

    private var settings: Settings {
        Settings(
            text: text,
            font: font,
            color: color,
            rate: rate,
            isReversed: isReversed,
            fadeLength: fadeLength,
            trailingBuffer: trailingBuffer,
            pauseDuration: pauseDuration,
            isLabelized: isLabelized,
            isHeld: isHeld
        )
    }

    private func apply(to label: MarqueeLabel, coordinator: Coordinator) {
        let next = settings
        guard coordinator.applied != next else { return }
        coordinator.applied = next

        label.type = isReversed ? .continuousReverse : .continuous
        label.text = text
        label.font = font
        label.textColor = UIColor(color)
        label.speed = .rate(rate)
        label.fadeLength = fadeLength
        label.trailingBuffer = trailingBuffer
        label.animationDelay = pauseDuration

        label.labelize = isLabelized
        label.holdScrolling = isHeld
    }
}

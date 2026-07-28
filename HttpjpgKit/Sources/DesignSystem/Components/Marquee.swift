import MarqueeLabel
import SwiftUI
import UIKit

/// Continuously scrolling strip of text — port of `@httpjpg/ui`'s `<Marquee>`.
///
/// Backed by `MarqueeLabel`, which owns the scroll animation, edge fades and
/// the "don't scroll if it already fits" behaviour. Reduce Motion switches the
/// label into `labelize` mode, i.e. a plain truncated `UILabel`.
public struct Marquee: View {
    /// How fast the strip moves.
    public enum Speed: Sendable {
        /// Points per second, straight through to `MarqueeLabel`.
        case rate(CGFloat)
        /// Seconds for one copy of the text to pass — the web's `speed` prop,
        /// which is a CSS animation duration and therefore independent of how
        /// long the string happens to be.
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
    /// Explicit text colour; `nil` follows the page theme. Chrome that floats
    /// over arbitrary content passes its own, because no page theme can be
    /// right for a strip that sits above a photograph.
    private let color: Color?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.pageTheme) private var theme

    /// - Parameters:
    ///   - text: The string to scroll.
    ///   - font: A UIKit font — use ``Typography/uiMono(_:weight:)`` or
    ///     ``Typography/uiSans(_:weight:)`` to stay on the token scale.
    ///   - speed: Rate or seconds-per-copy.
    ///   - direction: Which way the text travels.
    ///   - repeatCount: How many copies of the text make up the strip. This is
    ///     not decoration — `MarqueeLabel` refuses to scroll a label that
    ///     already fits its frame, so a short line on a wide phone just sat
    ///     there. Repeating it, exactly as the web does, is what makes it move.
    ///   - fadeLength: Width of the gradient fade at each edge.
    ///   - trailingBuffer: Gap between the end of the text and its repeat.
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

    /// A representable reports its intrinsic size to SwiftUI, and a label's
    /// intrinsic width is its whole string — which for a repeated marquee is
    /// several screens wide. Proposing the offered width instead keeps the
    /// strip inside the layout and lets `MarqueeLabel` do the overflowing.
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
        // `labelize` freezes the marquee into an ordinary truncating label.
        label.labelize = isLabelized
    }
}

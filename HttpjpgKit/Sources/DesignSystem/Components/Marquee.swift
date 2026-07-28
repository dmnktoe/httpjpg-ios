import MarqueeLabel
import SwiftUI
import UIKit

/// Continuously scrolling strip of text — port of `@httpjpg/ui`'s `<Marquee>`.
///
/// Backed by `MarqueeLabel`, which owns the scroll animation, edge fades and
/// the "don't scroll if it already fits" behaviour. Reduce Motion switches the
/// label into `labelize` mode, i.e. a plain truncated `UILabel`.
public struct Marquee: View {
    private let text: String
    private let font: UIFont
    private let rate: CGFloat
    private let fadeLength: CGFloat
    private let trailingBuffer: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.pageTheme) private var theme

    /// - Parameters:
    ///   - text: The string to scroll.
    ///   - font: A UIKit font — use ``Typography/uiMono(_:weight:)`` or
    ///     ``Typography/uiSans(_:weight:)`` to stay on the token scale.
    ///   - rate: Scroll speed in points per second.
    ///   - fadeLength: Width of the gradient fade at each edge.
    ///   - trailingBuffer: Gap between the end of the text and its repeat.
    public init(
        _ text: String,
        font: UIFont = Typography.uiMono(Typography.Size.sm),
        rate: CGFloat = 30,
        fadeLength: CGFloat = 12,
        trailingBuffer: CGFloat = 32
    ) {
        self.text = text
        self.font = font
        self.rate = rate
        self.fadeLength = fadeLength
        self.trailingBuffer = trailingBuffer
    }

    public var body: some View {
        MarqueeLabelView(
            text: text,
            font: font,
            color: UIColor(theme.foreground),
            rate: rate,
            fadeLength: fadeLength,
            trailingBuffer: trailingBuffer,
            isLabelized: reduceMotion
        )
        .frame(height: font.lineHeight)
        .accessibilityElement()
        .accessibilityLabel(text)
    }
}

private struct MarqueeLabelView: UIViewRepresentable {
    let text: String
    let font: UIFont
    let color: UIColor
    let rate: CGFloat
    let fadeLength: CGFloat
    let trailingBuffer: CGFloat
    let isLabelized: Bool

    func makeUIView(context: Context) -> MarqueeLabel {
        let label = MarqueeLabel(frame: .zero, rate: rate, fadeLength: fadeLength)
        label.type = .continuous
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

    private func apply(to label: MarqueeLabel) {
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

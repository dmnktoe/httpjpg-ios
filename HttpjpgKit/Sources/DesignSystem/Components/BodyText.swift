import SwiftUI

/// Running text — the Swift port of `@httpjpg/ui`'s `<Paragraph>`.
///
/// Named `BodyText` rather than `Paragraph` so it can't be confused with
/// `RichText.Paragraph` from the Storyblok SDK, which the blok renderers use.
public struct BodyText: View {
    public enum Size: Sendable {
        case sm
        case md
        case lg
        case xl

        var points: CGFloat {
            switch self {
            case .sm: return Typography.Size.sm
            case .md: return Typography.Size.md
            case .lg: return Typography.Size.lg
            case .xl: return Typography.Size.xl
            }
        }

        /// The web uses `line-height: 1.75` (1.8 at lg/xl); SwiftUI's
        /// `lineSpacing` is the *gap*, so subtract the font size back out.
        var lineSpacing: CGFloat {
            switch self {
            case .sm, .md: return points * 0.75
            case .lg, .xl: return points * 0.8
            }
        }
    }

    public enum Emphasis: Sendable {
        case `default`
        case muted
        case dimmed

        var opacity: Double {
            switch self {
            case .default: return 1
            case .muted: return 0.7
            case .dimmed: return 0.5
            }
        }
    }

    private let text: String
    private let size: Size
    private let emphasis: Emphasis
    private let weight: Font.Weight
    private let alignment: TextAlignment
    private let lineLimit: Int?
    private let lineHeight: CGFloat?

    /// - Parameter lineHeight: Overrides the size's own leading, as a multiple
    ///   of the font size. Running copy wants the web's airy 1.75; a card
    ///   summary sitting under a headline wants far less, or the block reads as
    ///   five loose lines instead of one paragraph.
    public init(
        _ text: String,
        size: Size = .sm,
        emphasis: Emphasis = .default,
        weight: Font.Weight = .regular,
        alignment: TextAlignment = .leading,
        lineLimit: Int? = nil,
        lineHeight: CGFloat? = nil
    ) {
        self.text = text
        self.size = size
        self.emphasis = emphasis
        self.weight = weight
        self.alignment = alignment
        self.lineLimit = lineLimit
        self.lineHeight = lineHeight
    }

    public var body: some View {
        Text(text)
            .font(Typography.sans(size.points).weight(weight))
            .lineSpacing(lineHeight.map { size.points * ($0 - 1) } ?? size.lineSpacing)
            .multilineTextAlignment(alignment)
            .opacity(emphasis.opacity)
            .lineLimit(lineLimit)
            .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .leading)
    }
}

/// Monospaced meta text — the `fontFamily: "mono"` rows that carry dates,
/// slugs and ASCII furniture on work cards.
public struct MonoText: View {
    private let text: String
    private let size: CGFloat
    private let tracking: CGFloat
    private let opacity: Double

    public init(
        _ text: String,
        size: CGFloat = Typography.Size.sm,
        tracking: CGFloat = 0,
        opacity: Double = 1
    ) {
        self.text = text
        self.size = size
        self.tracking = tracking
        self.opacity = opacity
    }

    public var body: some View {
        Text(text)
            .font(Typography.mono(size))
            .tracking(tracking)
            .opacity(opacity)
    }
}

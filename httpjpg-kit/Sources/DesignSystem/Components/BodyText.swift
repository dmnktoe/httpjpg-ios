import SwiftUI

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

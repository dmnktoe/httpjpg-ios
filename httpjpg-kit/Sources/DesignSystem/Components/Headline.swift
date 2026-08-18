import SwiftUI
import Tokens

public struct Headline: View {
    public enum Level: Int, Sendable, CaseIterable {
        case one = 1
        case two = 2
        case three = 3

        var clamp: (min: CGFloat, slope: CGFloat, intercept: CGFloat, max: CGFloat) {
            switch self {
            case .one: return (36, 0.05, 16, 60)
            case .two: return (30, 0.04, 16, 48)
            case .three: return (24, 0.03, 8, 36)
            }
        }

        var trackingRatio: CGFloat {
            switch self {
            case .one, .two: return -0.05
            case .three: return -0.025
            }
        }
    }

    private let text: String
    private let level: Level
    private let alignment: TextAlign
    private let lineSpacingRatio: CGFloat

    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.pageTheme) private var theme

    public init(
        _ text: String,
        level: Level = .one,
        alignment: TextAlign = .left,
        lineSpacing: CGFloat = -0.25
    ) {
        self.text = text
        self.level = level
        self.alignment = alignment
        self.lineSpacingRatio = lineSpacing
    }

    public var body: some View {
        let size = resolvedSize
        Group {
            if alignment == .justify {
                AlignedText(
                    text,
                    align: alignment,
                    font: Typography.uiHeadline(size),
                    color: theme.foreground
                )
            } else {
                Text(text)
                    .font(Typography.headline(size))
                    .tracking(size * level.trackingRatio)
                    .lineSpacing(size * lineSpacingRatio)
                    .multilineTextAlignment(alignment.multiline)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment.frame)
        .accessibilityAddTraits(.isHeader)
    }

    private var resolvedSize: CGFloat {
        let spec = level.clamp
        return Typography.clamp(
            min: spec.min,
            slope: spec.slope,
            intercept: spec.intercept,
            max: spec.max,
            width: viewportWidth
        )
    }
}

#Preview {
    VStack(alignment: .leading, spacing: Spacing.s6) {
        Headline("dominik toe", level: .one)
        Headline("selected work", level: .two)
        Headline("about", level: .three)
    }
    .padding(PageLayout.gutter)
    .pageSurface(.light)
}

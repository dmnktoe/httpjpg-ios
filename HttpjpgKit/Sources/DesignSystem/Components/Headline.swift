import SwiftUI

/// Display type — the Swift port of `@httpjpg/ui`'s `<Headline>`.
///
/// Levels keep the web's clamped sizes, evaluated against
/// ``EnvironmentValues/viewportWidth`` instead of the browser's `vw` unit.
public struct Headline: View {
    public enum Level: Int, Sendable, CaseIterable {
        case one = 1
        case two = 2
        case three = 3

        /// `clamp(min, slope·vw + intercept, max)` per level, from `headline.tsx`.
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
    private let alignment: TextAlignment

    @Environment(\.viewportWidth) private var viewportWidth

    public init(_ text: String, level: Level = .one, alignment: TextAlignment = .leading) {
        self.text = text
        self.level = level
        self.alignment = alignment
    }

    public var body: some View {
        let size = resolvedSize
        Text(text)
            .font(Typography.headline(size))
            .tracking(size * level.trackingRatio)
            .multilineTextAlignment(alignment)
            .frame(maxWidth: .infinity, alignment: frameAlignment)
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

    private var frameAlignment: Alignment {
        switch alignment {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
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

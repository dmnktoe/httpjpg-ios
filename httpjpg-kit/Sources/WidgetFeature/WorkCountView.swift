import DesignSystem
import SwiftUI
import Tokens
import WidgetKit

struct WorkCountView: View {
    let entry: WorkCountEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        if entry.total == 0 {
            WidgetEmptyState(message: entry.message)
        } else {
            switch family {
            case .accessoryInline:
                Text("㋡ \(entry.total) works")
                    .font(Typography.mono(Typography.Size.sm, weight: .bold))
            case .accessoryCircular:
                circular
            case .accessoryRectangular:
                rectangular
            default:
                small
            }
        }
    }

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text(entry.stamp)
                    .font(Typography.mono(16, weight: .bold))
                Text("works")
                    .font(Typography.mono(Typography.Size.xxs))
                    .opacity(Opacities.muted)
            }
        }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("\(entry.stamp) works")
                .font(Typography.mono(Typography.Size.sm, weight: .bold))
            Text(split)
                .font(Typography.mono(Typography.Size.xxs))
                .opacity(Opacities.muted)
            if let span = entry.span {
                Text(span)
                    .font(Typography.mono(Typography.Size.xxs))
                    .opacity(Opacities.subtle)
            }
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            AsciiTape()

            Text(entry.stamp)
                .font(Typography.headline(52, relativeTo: .largeTitle))
                .tracking(Typography.Tracking.tight(52))
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            VStack(alignment: .leading, spacing: 1) {
                Text("works")
                    .font(Typography.mono(Typography.Size.xs, weight: .bold))
                Text(split)
                    .font(Typography.mono(Typography.Size.xxs))
                    .opacity(Opacities.muted)
                if let span = entry.span {
                    Text(span)
                        .font(Typography.mono(Typography.Size.xxs))
                        .opacity(Opacities.subtle)
                }
            }
            .lineLimit(1)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var split: String {
        "\(entry.projects) projects · \(entry.websites) websites"
    }
}

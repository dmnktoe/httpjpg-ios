import DesignSystem
import SwiftUI
import Tokens
import WidgetKit

struct SiteStatusView: View {
    let entry: SiteStatusEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryInline:
            inline
        case .accessoryRectangular:
            stack(lines: 3, showsLabels: false, size: Typography.Size.xxs)
        case .systemMedium:
            stack(lines: 4, showsLabels: true, size: Typography.Size.sm)
        default:
            stack(lines: 4, showsLabels: false, size: Typography.Size.xxs)
        }
    }

    private var inline: some View {
        Text(entry.lines.first.map { "\($0.badge) \($0.text)" } ?? "httpjpg")
            .font(Typography.mono(Typography.Size.sm, weight: .bold))
    }

    @ViewBuilder
    private func stack(lines limit: Int, showsLabels: Bool, size: CGFloat) -> some View {
        if entry.lines.isEmpty {
            WidgetEmptyState(message: entry.message)
        } else {
            VStack(alignment: .leading, spacing: Spacing.s1) {
                if showsLabels {
                    AsciiTape()
                }
                ForEach(entry.lines.prefix(limit)) { line in
                    row(line, showsLabel: showsLabels, size: size)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func row(_ line: SiteStatusLine, showsLabel: Bool, size: CGFloat) -> some View {
        HStack(spacing: Spacing.s1) {
            if showsLabel {
                Text(line.label)
                    .opacity(Opacities.subtle)
            }
            Text(line.badge)
            Text(line.text)
                .foregroundStyle(line.tint ?? .primary)
                .lineLimit(1)
            if let detail = line.detail {
                Text(detail)
                    .opacity(Opacities.muted)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer(minLength: 0)
        }
        .font(Typography.mono(size))
        .accessibilityElement(children: .combine)
    }
}

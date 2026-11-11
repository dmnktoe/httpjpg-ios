import StoryblokCore
import SwiftUI
import Tokens
import WidgetKit

struct WorkGridView: View {
    let entry: WorkGridEntry

    @Environment(\.widgetFamily) private var family
    @Environment(\.pageTheme) private var theme

    private static let gutter = Spacing.s2
    private static let rowGap = Spacing.s3

    var body: some View {
        if entry.items.isEmpty {
            WidgetEmptyState(message: entry.message ?? "nothing to show")
        } else {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                header
                grid
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s2) {
            Text(Ascii.tape)
                .font(Typography.mono(7))
                .opacity(Opacities.tape)
                .lineLimit(1)
                .accessibilityHidden(true)
            Spacer(minLength: 0)
            if let span {
                Text(span)
                    .font(Typography.mono(Typography.Size.xxs))
                    .opacity(Opacities.subtle)
            }
        }
    }

    private var grid: some View {
        GeometryReader { proxy in
            let width = (proxy.size.width - Self.gutter * CGFloat(columns - 1)) / CGFloat(columns)
            let height = (proxy.size.height - Self.rowGap * CGFloat(rowCount - 1)) / CGFloat(rowCount)

            VStack(alignment: .leading, spacing: Self.rowGap) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: Self.gutter) {
                        ForEach(row) { item in
                            tile(item)
                                .frame(width: max(width, 0), height: max(height, 0))
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func tile(_ item: WorkItem) -> some View {
        if let destination = destination(of: item) {
            Link(destination: destination) { card(item) }
                .foregroundStyle(theme.foreground)
                .accessibilityLabel(item.title)
        } else {
            card(item)
                .accessibilityLabel(item.title)
        }
    }

    private func card(_ item: WorkItem) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay { thumbnail(of: item) }
                .clipped()

            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(Typography.sansBold(Typography.Size.sm))
                    .lineLimit(1)
                if let date = item.date {
                    Text(WorkCardDate.year(of: date))
                        .font(Typography.mono(Typography.Size.xs))
                        .opacity(Opacities.subtle)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func thumbnail(of item: WorkItem) -> some View {
        if let image = entry.frames[item.id] {
            Image(uiImage: image)
                .resizable()
                .widgetFullColor()
                .scaledToFill()
        } else {
            theme.border.opacity(Opacities.dimmed)
        }
    }

    private var span: String? {
        let years = entry.items.compactMap(\.date).map(WorkCardDate.year(of:))
        guard let first = years.min(), let latest = years.max() else { return nil }
        return first == latest ? first : "\(first)–\(latest)"
    }

    private var columns: Int {
        WorkGridLayout.columns(for: family)
    }

    private var rowCount: Int {
        WorkGridLayout.rows(for: family)
    }

    private var rows: [[WorkItem]] {
        let items = Array(entry.items.prefix(WorkGridLayout.tiles(for: family)))
        return stride(from: 0, to: items.count, by: columns).map { start in
            Array(items[start ..< min(start + columns, items.count)])
        }
    }

    private func destination(of item: WorkItem) -> URL? {
        if item.isExternal, let external = item.externalURL {
            return external
        }
        return WidgetDeepLink.work(slug: item.slug)
    }
}

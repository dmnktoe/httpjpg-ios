import DesignSystem
import StoryblokContent
import SwiftUI
import WidgetKit

struct ContactSheetView: View {
    let entry: ContactSheetEntry

    @Environment(\.widgetFamily) private var family
    @Environment(\.pageTheme) private var theme

    private static let gutter: CGFloat = 2

    var body: some View {
        if entry.items.isEmpty {
            WidgetEmptyState(message: entry.message ?? "nothing to show")
        } else {
            Grid(horizontalSpacing: Self.gutter, verticalSpacing: Self.gutter) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    GridRow {
                        ForEach(row) { tile($0) }
                        ForEach(0 ..< (columns - row.count), id: \.self) { _ in
                            Color.clear
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func tile(_ item: WorkItem) -> some View {
        if let destination = destination(of: item) {
            Link(destination: destination) { cell(item) }
                .accessibilityLabel(item.title)
        } else {
            cell(item)
                .accessibilityLabel(item.title)
        }
    }

    private func cell(_ item: WorkItem) -> some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                if let image = entry.frames[item.id] {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    placeholder(item)
                }
            }
            .clipped()
    }

    private func placeholder(_ item: WorkItem) -> some View {
        theme.border.opacity(Opacities.dimmed)
            .overlay {
                Text(item.title)
                    .font(Typography.mono(Typography.Size.xxs))
                    .opacity(Opacities.muted)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(2)
            }
    }

    private var columns: Int {
        ContactSheetLayout.columns(for: family)
    }

    private var rows: [[WorkItem]] {
        stride(from: 0, to: entry.items.count, by: columns).map { start in
            Array(entry.items[start ..< min(start + columns, entry.items.count)])
        }
    }

    private func destination(of item: WorkItem) -> URL? {
        if item.isExternal, let external = item.externalURL {
            return external
        }
        return WidgetDeepLink.work(slug: item.slug)
    }
}

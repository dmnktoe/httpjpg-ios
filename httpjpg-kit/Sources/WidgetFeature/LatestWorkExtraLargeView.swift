import DesignSystem
import StoryblokContent
import SwiftUI

struct LatestWorkExtraLargeView: View {
    let entry: LatestWorkEntry

    @Environment(\.pageTheme) private var theme

    private static let columns = 2

    var body: some View {
        HStack(spacing: 0) {
            hero
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            recent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(16)
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            artwork
            LinearGradient(
                colors: [.black.opacity(0), .black.opacity(0.8)],
                startPoint: .center,
                endPoint: .bottom
            )
            VStack(alignment: .leading, spacing: 4) {
                Text(Ascii.tape)
                    .font(Typography.mono(8))
                    .opacity(Opacities.tape)
                    .lineLimit(1)
                Text(entry.featured?.title ?? "nothing yet")
                    .font(Typography.headline(30, relativeTo: .title))
                    .tracking(-0.6)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                if let year = year(of: entry.featured) {
                    Text(year)
                        .font(Typography.mono(Typography.Size.xs))
                        .opacity(Opacities.subtle)
                }
            }
            .foregroundStyle(.white)
            .padding(16)
        }
        .clipped()
    }

    @ViewBuilder
    private var artwork: some View {
        if let image = entry.image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            theme.background
                .overlay {
                    AsciiArt(
                        Ascii.ghost,
                        label: "",
                        size: Typography.Size.sm,
                        opacity: Opacities.dimmed
                    )
                }
        }
    }

    private var recent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Ascii.tape)
                .font(Typography.mono(7))
                .opacity(Opacities.tape)
                .lineLimit(1)

            if rows.isEmpty {
                Text(entry.message ?? "nothing to show")
                    .font(Typography.mono(Typography.Size.xs))
                    .opacity(Opacities.subtle)
                    .lineLimit(3)
            } else {
                Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        GridRow {
                            ForEach(row) { tile($0) }
                            ForEach(0 ..< (Self.columns - row.count), id: \.self) { _ in
                                Color.clear
                            }
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func tile(_ item: WorkItem) -> some View {
        if let destination = destination(of: item) {
            Link(destination: destination) { card(item) }
                .foregroundStyle(theme.foreground)
        } else {
            card(item)
        }
    }

    private func card(_ item: WorkItem) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            thumbnail(of: item)
                .frame(maxWidth: .infinity)
                .frame(height: 78)
                .clipped()

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                if let year = year(of: item) {
                    Text(year)
                        .font(Typography.mono(Typography.Size.xs))
                        .opacity(Opacities.subtle)
                }
                Text(item.title)
                    .font(Typography.sansBold(Typography.Size.sm))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func thumbnail(of item: WorkItem) -> some View {
        if let image = entry.thumbnails[item.id] {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            theme.border.opacity(0.3)
        }
    }

    private var rows: [[WorkItem]] {
        let items = Array(entry.items.dropFirst())
        return stride(from: 0, to: items.count, by: Self.columns).map { start in
            Array(items[start ..< min(start + Self.columns, items.count)])
        }
    }

    private func year(of item: WorkItem?) -> String? {
        guard let date = item?.date else { return nil }
        return WorkCardDate.year(of: date)
    }

    private func destination(of item: WorkItem) -> URL? {
        if item.isExternal, let external = item.externalURL {
            return external
        }
        return WidgetDeepLink.work(slug: item.slug)
    }
}

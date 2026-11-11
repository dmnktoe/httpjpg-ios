import StoryblokCore
import SwiftUI
import Tokens

struct LatestWorkListView: View {
    let entry: LatestWorkEntry
    let isLarge: Bool

    @Environment(\.pageTheme) private var theme

    var body: some View {
        if isLarge {
            VStack(alignment: .leading, spacing: 10) {
                linked(entry.featured) {
                    featured
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                        .clipped()
                }
                rows
            }
        } else {
            HStack(spacing: 12) {
                linked(entry.featured) {
                    featured
                        .frame(width: 110)
                        .clipped()
                }
                rows
            }
        }
    }

    // The picture sits in an overlay so the link is as large as its frame: a
    // filled image reports its overflowing size, and the link would reach over the rows.
    private var featured: some View {
        Color.clear
            .overlay {
                if let image = entry.image {
                    Image(uiImage: image)
                        .resizable()
                        .widgetFullColor()
                        .scaledToFill()
                } else {
                    theme.border.opacity(0.3)
                }
            }
    }

    private var rows: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Ascii.tape)
                .font(Typography.mono(7))
                .opacity(Opacities.tape)
                .lineLimit(1)

            ForEach(entry.items.prefix(isLarge ? 4 : 3)) { item in
                linked(item) { row(item) }
            }

            if entry.items.isEmpty {
                Text(entry.message ?? "nothing to show")
                    .font(Typography.mono(Typography.Size.xs))
                    .opacity(Opacities.subtle)
                    .lineLimit(3)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Each row carries its own link; the widget-wide URL only catches taps
    // between them and would otherwise send every row to the featured work.
    @ViewBuilder
    private func linked<Content: View>(
        _ item: WorkItem?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if let item, let destination = destination(of: item) {
            Link(destination: destination, label: content)
                .foregroundStyle(theme.foreground)
        } else {
            content()
        }
    }

    private func destination(of item: WorkItem) -> URL? {
        if item.isExternal, let external = item.externalURL {
            return external
        }
        return WidgetDeepLink.work(slug: item.slug)
    }

    private func row(_ item: WorkItem) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                if let date = item.date {
                    Text(WorkCardDate.year(of: date))
                        .font(Typography.mono(Typography.Size.xs))
                        .opacity(Opacities.subtle)
                }
                Text(item.title)
                    .font(Typography.sansBold(Typography.Size.sm))
                    .lineLimit(1)
            }
            if isLarge, !item.summary.isEmpty {
                Text(item.summary)
                    .font(Typography.sans(Typography.Size.xs))
                    .opacity(Opacities.muted)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

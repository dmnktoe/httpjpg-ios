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
                featured
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .clipped()
                rows
            }
        } else {
            HStack(spacing: 12) {
                featured
                    .frame(width: 110)
                    .clipped()
                rows
            }
        }
    }

    @ViewBuilder
    private var featured: some View {
        if let image = entry.image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            theme.border.opacity(0.3)
        }
    }

    private var rows: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Ascii.tape)
                .font(Typography.mono(7))
                .opacity(Opacities.tape)
                .lineLimit(1)

            ForEach(entry.items.prefix(isLarge ? 4 : 3)) { item in
                row(item)
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

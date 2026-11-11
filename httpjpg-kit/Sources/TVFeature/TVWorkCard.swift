import StoryblokCore
import SwiftUI
import Tokens

struct TVWorkCard: View {
    let item: WorkItem

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            NavigationLink(value: item) {
                Color.clear
                    .aspectRatio(16.0 / 9.0, contentMode: .fit)
                    .overlay {
                        TVImage(filename: item.imageFilenames.first, targetWidth: TVMetrics.posterWidth)
                    }
                    .clipped()
            }
            .tvCardStyle()
            .accessibilityLabel(item.title)

            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(item.title)
                    .font(Typography.sansBold(TVMetrics.caption))
                    .lineLimit(1)
                if let date = item.date {
                    Text(WorkCardDate.year(of: date))
                        .font(Typography.mono(TVMetrics.label))
                        .opacity(Opacities.subtle)
                }
            }
            .accessibilityHidden(true)
        }
    }
}

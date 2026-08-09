import StoryblokCore
import SwiftUI
import Tokens

struct WatchWorkRow: View {
    let item: WorkItem

    private static let thumbnailSide: CGFloat = 40

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.s2) {
            WatchThumbnail(filename: item.imageFilenames.first, targetWidth: Self.thumbnailSide)
                .frame(width: Self.thumbnailSide, height: Self.thumbnailSide)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(Typography.headline(15, relativeTo: .headline))
                    .tracking(-0.4)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.leading)

                Text(caption)
                    .font(Typography.mono(Typography.Size.xxs))
                    .opacity(Opacities.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Spacing.s1)
        .accessibilityElement(children: .combine)
    }

    private var caption: String {
        let stamp = item.date.map(WorkCardDate.stamp(of:)) ?? WorkYearGroup.undatedYear
        return item.isExternal ? stamp + " ↗" : stamp
    }
}

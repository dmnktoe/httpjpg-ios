import StoryblokCore
import SwiftUI
import Tokens

struct WatchWorkDetailScreen: View {
    let item: WorkItem

    @Environment(WatchAppModel.self) private var model

    private var stills: [WorkMedia] {
        item.media.filter { !$0.isVideo }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s3) {
                hero

                Text(item.title)
                    .font(Typography.headline(22, relativeTo: .title))
                    .tracking(-1)
                    .multilineTextAlignment(.leading)

                if let date = item.date {
                    Text(WorkCardDate.stamp(of: date))
                        .font(Typography.mono(Typography.Size.xs))
                        .opacity(Opacities.muted)
                }

                Text(Ascii.dividerDots)
                    .font(Typography.mono(Typography.Size.xxs))
                    .opacity(Opacities.subtle)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)

                if !item.summary.isEmpty {
                    Text(item.summary)
                        .font(Typography.sans(Typography.Size.sm))
                        .lineSpacing(Typography.Size.sm * 0.5)
                        .multilineTextAlignment(.leading)
                }

                if !tags.isEmpty {
                    Text(tags)
                        .font(Typography.mono(Typography.Size.xxs))
                        .opacity(Opacities.muted)
                }

                gallery

                footer
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.s1)
            .padding(.bottom, Spacing.s4)
        }
        .navigationTitle("")
    }

    @ViewBuilder
    private var hero: some View {
        if let first = stills.first {
            frame(for: first)
        }
    }

    private var gallery: some View {
        ForEach(stills.dropFirst(), id: \.self) { media in
            frame(for: media)
        }
    }

    private func frame(for media: WorkMedia) -> some View {
        WatchThumbnail(
            filename: media.filename,
            targetWidth: Self.frameWidth,
            aspectRatio: ImageService.aspectRatio(of: media.filename) ?? Self.fallbackRatio
        )
    }

    private static let frameWidth: CGFloat = 180

    private static let fallbackRatio: CGFloat = 3.0 / 2.0

    private var footer: some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(Ascii.tape)
                .font(Typography.mono(Typography.Size.xxs))
                .opacity(Opacities.tape)
                .lineLimit(1)

            Text(canonical)
                .font(Typography.mono(Typography.Size.xxs))
                .opacity(Opacities.muted)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tags: String {
        item.tags.map { "#" + $0.lowercased() }.joined(separator: " ")
    }

    private var canonical: String {
        let url = item.externalURL ?? item.canonicalURL(siteOrigin: model.client.configuration.siteOrigin)
        return (url.host().map { $0 + url.path() } ?? url.absoluteString)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
}

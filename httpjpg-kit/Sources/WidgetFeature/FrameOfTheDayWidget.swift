import StoryblokCore
import SwiftUI
import Tokens
import WidgetKit

public struct FrameOfTheDayWidget: Widget {
    public static let kind = "com.yl33ly.httpjpg.frame-of-the-day"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: FrameOfTheDayProvider()) { entry in
            FrameOfTheDayWidgetView(entry: entry)
        }
        .configurationDisplayName("Feed")
        .description("A picture, track, or clip from the feed, swapped at midnight.")

        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
        .contentMarginsDisabled()
    }
}

struct FrameOfTheDayWidgetView: View {
    let entry: FrameOfTheDayEntry

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        content
            .pageTheme(theme)
            .widgetURL(WidgetDeepLink.page(slug: StorySlug.feed))
            .containerBackground(for: .widget) {
                theme.background
            }
    }

    @ViewBuilder
    private var content: some View {
        switch entry.content {
        case .image:
            if let image = entry.image {
                Image(uiImage: image)
                    .resizable()
                    .widgetFullColor()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .accessibilityLabel("Frame of the day")
            } else {
                WidgetEmptyState(message: entry.message)
            }
        case .music(let title, let artist, let playURL, let listenURL):
            FrameOfTheDayMusicView(
                title: title,
                artist: artist,
                artwork: entry.image,
                actionURL: playURL ?? listenURL,
                playsInApp: playURL != nil
            )
        case .video(let caption):
            FrameOfTheDayVideoView(image: entry.image, caption: caption)
        }
    }

    private var theme: PageTheme {
        colorScheme == .dark ? .dark : .light
    }
}

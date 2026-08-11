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
        .configurationDisplayName("Frame of the day")
        .description("One picture from the feed, swapped at midnight.")

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
        if let image = entry.image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .accessibilityLabel("Frame of the day")
        } else {
            WidgetEmptyState(message: entry.message)
        }
    }

    private var theme: PageTheme {
        colorScheme == .dark ? .dark : .light
    }
}

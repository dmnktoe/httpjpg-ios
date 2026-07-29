import DesignSystem
import SwiftUI
import WidgetKit

/// Home-screen widget showing the newest work.
///
/// The small family is the one this was designed around: the featured piece
/// full-bleed, an ASCII tape strip, and the title on a scrim. Medium and large
/// add the recent list beside it — resizing a widget is something people do,
/// and the alternative is the system refusing the size.
public struct LatestWorkWidget: Widget {
    public static let kind = "com.httpjpg.portfolio.latest-work"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: LatestWorkProvider()) { entry in
            LatestWorkWidgetView(entry: entry)
        }
        .configurationDisplayName("Latest work")
        .description("The newest piece from httpjpg.com.")
        // The accessory families put the newest piece on the lock screen and
        // Apple Watch; StandBy just runs the small family fullscreen.
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryInline, .accessoryRectangular, .accessoryCircular,
        ])
        .contentMarginsDisabled()
    }
}

/// Dispatches on family and supplies the widget container background.
///
/// `contentMarginsDisabled()` above plus this container background is what
/// lets the small family run its image edge to edge; without both, the system
/// insets the content and the photo ends up floating in a margin.
struct LatestWorkWidgetView: View {
    let entry: LatestWorkEntry

    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        content
            .pageTheme(theme)
            .widgetURL(deepLink)
            .containerBackground(for: .widget) {
                // The lock screen supplies its own vibrant material; painting
                // a page colour under it would just dim the text.
                if !isAccessory {
                    theme.background
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryInline, .accessoryRectangular, .accessoryCircular:
            LatestWorkAccessoryView(entry: entry)
        case .systemSmall:
            LatestWorkSmallView(entry: entry)
        case .systemLarge:
            LatestWorkListView(entry: entry, isLarge: true)
                .padding(14)
        default:
            LatestWorkListView(entry: entry, isLarge: false)
                .padding(14)
        }
    }

    private var isAccessory: Bool {
        switch family {
        case .accessoryInline, .accessoryRectangular, .accessoryCircular: return true
        default: return false
        }
    }

    /// The widget follows the system appearance rather than the app's stored
    /// preference: on the home screen it sits among system-styled widgets, and
    /// an extension cannot see the app's `@AppStorage` without an app group.
    private var theme: PageTheme {
        colorScheme == .dark ? .dark : .light
    }

    private var deepLink: URL? {
        guard let slug = entry.featured?.slug else { return nil }
        return WidgetDeepLink.work(slug: slug)
    }
}

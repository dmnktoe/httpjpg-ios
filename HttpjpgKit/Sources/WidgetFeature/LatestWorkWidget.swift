import DesignSystem
import SwiftUI
import WidgetKit

public struct LatestWorkWidget: Widget {
    public static let kind = "com.httpjpg.portfolio.latest-work"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: LatestWorkProvider()) { entry in
            LatestWorkWidgetView(entry: entry)
        }
        .configurationDisplayName("Latest work")
        .description("The newest piece from httpjpg.com.")

        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryInline, .accessoryRectangular, .accessoryCircular,
        ])
        .contentMarginsDisabled()
    }
}

struct LatestWorkWidgetView: View {
    let entry: LatestWorkEntry

    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        content
            .pageTheme(theme)
            .widgetURL(deepLink)
            .containerBackground(for: .widget) {
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

    private var theme: PageTheme {
        colorScheme == .dark ? .dark : .light
    }

    private var deepLink: URL? {
        guard let slug = entry.featured?.slug else { return nil }
        return WidgetDeepLink.work(slug: slug)
    }
}

import DesignSystem
import SwiftUI
import WidgetKit

public struct SiteStatusWidget: Widget {
    public static let kind = "com.yl33ly.httpjpg.status"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: SiteStatusProvider()) { entry in
            SiteStatusWidgetView(entry: entry)
        }
        .configurationDisplayName("Status")
        .description("The footer lines: presence, the last film, the last trophy, the weather.")

        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

struct SiteStatusWidgetView: View {
    let entry: SiteStatusEntry

    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        SiteStatusView(entry: entry)
            .pageTheme(theme)
            .widgetURL(WidgetDeepLink.info)
            .containerBackground(for: .widget) {
                if !isAccessory {
                    theme.background
                }
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
}

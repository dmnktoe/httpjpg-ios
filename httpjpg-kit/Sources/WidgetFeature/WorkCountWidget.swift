import DesignSystem
import SwiftUI
import WidgetKit

public struct WorkCountWidget: Widget {
    public static let kind = "com.yl33ly.httpjpg.work-count"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: WorkCountProvider()) { entry in
            WorkCountWidgetView(entry: entry)
        }
        .configurationDisplayName("Index")
        .description("How much is in the archive, and how far back it goes.")

        .supportedFamilies([
            .systemSmall, .accessoryInline, .accessoryRectangular, .accessoryCircular,
        ])
    }
}

struct WorkCountWidgetView: View {
    let entry: WorkCountEntry

    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        WorkCountView(entry: entry)
            .pageTheme(theme)
            .widgetURL(WidgetDeepLink.workIndex)
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

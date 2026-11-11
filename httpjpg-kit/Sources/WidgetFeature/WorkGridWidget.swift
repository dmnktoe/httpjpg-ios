import SwiftUI
import Tokens
import WidgetKit

public struct WorkGridWidget: Widget {
    public static let kind = "com.yl33ly.httpjpg.work-grid"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: WorkGridProvider()) { entry in
            WorkGridWidgetView(entry: entry)
        }
        .configurationDisplayName("Grid")
        .description("The portfolio as a grid of frames. Every frame opens its work.")

        .supportedFamilies([.systemMedium, .systemLarge, .systemExtraLarge])
        .contentMarginsDisabled()
    }
}

struct WorkGridWidgetView: View {
    let entry: WorkGridEntry

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        WorkGridView(entry: entry)
            .padding(14)
            .pageTheme(theme)
            .containerBackground(for: .widget) {
                theme.background
            }
    }

    private var theme: PageTheme {
        colorScheme == .dark ? .dark : .light
    }
}

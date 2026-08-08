import DesignSystem
import SwiftUI
import WidgetKit

public struct ContactSheetWidget: Widget {
    public static let kind = "com.yl33ly.httpjpg.contact-sheet"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: ContactSheetProvider()) { entry in
            ContactSheetWidgetView(entry: entry)
        }
        .configurationDisplayName("Contact sheet")
        .description("The portfolio as a grid of frames. Every frame opens its work.")

        // No small family: only one tap target fits there, and that is the latest-work widget.
        .supportedFamilies([.systemMedium, .systemLarge, .systemExtraLarge])
        .contentMarginsDisabled()
    }
}

struct ContactSheetWidgetView: View {
    let entry: ContactSheetEntry

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ContactSheetView(entry: entry)
            .pageTheme(theme)
            .containerBackground(for: .widget) {
                theme.background
            }
    }

    private var theme: PageTheme {
        colorScheme == .dark ? .dark : .light
    }
}

import DesignSystem
import SwiftUI
import WidgetKit

/// The lock-screen renditions of the latest-work widget. Monochrome by
/// contract — the system renders these vibrant/tinted — so they lean entirely
/// on the mono voice: glyph, tape, title.
struct LatestWorkAccessoryView: View {
    let entry: LatestWorkEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryInline:
            // One line next to the clock: the glyph is the brand, the title
            // is the news.
            Text("㋡ \(title)")
                .font(Typography.mono(Typography.Size.sm, weight: .bold))

        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Text("㋡")
                    .font(Typography.mono(22, weight: .bold))
            }

        default:
            // Rectangular: the small card's text block without its photo —
            // tape, then title, then where it lives.
            VStack(alignment: .leading, spacing: 1) {
                Text(Ascii.tape)
                    .font(Typography.mono(Typography.Size.xxs))
                    .opacity(0.55)
                    .lineLimit(1)
                Text(title)
                    .font(Typography.mono(Typography.Size.sm, weight: .bold))
                    .lineLimit(2)
                Text("▸ work/\(entry.featured?.slug ?? "…")")
                    .font(Typography.mono(Typography.Size.xxs))
                    .opacity(0.7)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var title: String {
        entry.featured?.title ?? entry.message ?? "httpjpg"
    }
}

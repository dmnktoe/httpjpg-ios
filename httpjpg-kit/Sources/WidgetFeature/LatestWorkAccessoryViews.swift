import SwiftUI
import Tokens
import WidgetKit

struct LatestWorkAccessoryView: View {
    let entry: LatestWorkEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryInline:

            Text("㋡ \(title)")
                .font(Typography.mono(Typography.Size.sm, weight: .bold))

        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Text("㋡")
                    .font(Typography.mono(22, weight: .bold))
            }

        default:

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

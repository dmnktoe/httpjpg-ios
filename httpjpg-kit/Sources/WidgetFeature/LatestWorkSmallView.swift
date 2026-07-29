import DesignSystem
import SwiftUI
import WidgetKit

struct LatestWorkSmallView: View {
    let entry: LatestWorkEntry

    @Environment(\.pageTheme) private var theme

    @Environment(\.widgetContentMargins) private var systemMargins

    var body: some View {
        caption
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .background { artwork }
            .clipped()
    }

    @ViewBuilder
    private var artwork: some View {
        if let image = entry.image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            theme.background
                .overlay {
                    AsciiArt(
                        Ascii.ghost,
                        label: "",
                        size: Typography.Size.sm,
                        opacity: Opacities.dimmed
                    )
                }
        }
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Ascii.tape)
                .font(Typography.mono(7))
                .opacity(0.7)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity, alignment: .leading)
                .clipped()
            Text(entry.featured?.title ?? "nothing yet")
                .font(Typography.headline(15, relativeTo: .caption))
                .tracking(-0.4)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.leading)
        }
        .foregroundStyle(.white)
        .padding(.leading, inset.leading)
        .padding(.trailing, inset.trailing)
        .padding(.bottom, inset.bottom)
        .padding(.top, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .bottom) { scrim }
    }

    private var inset: EdgeInsets {
        EdgeInsets(
            top: 0,
            leading: max(systemMargins.leading, 12),
            bottom: max(systemMargins.bottom, 10),
            trailing: max(systemMargins.trailing, 12)
        )
    }

    private var scrim: some View {
        LinearGradient(
            colors: [.black.opacity(0), .black.opacity(0.75)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

import SwiftUI
import Tokens
import WidgetKit

struct FrameOfTheDayVideoView: View {
    let image: UIImage?
    let caption: String?

    @Environment(\.pageTheme) private var theme
    @Environment(\.widgetContentMargins) private var systemMargins

    var body: some View {
        ZStack {
            artwork
            LinearGradient(
                colors: [.black.opacity(0), .black.opacity(0.72)],
                startPoint: .top,
                endPoint: .bottom
            )
            VStack(alignment: .leading, spacing: Spacing.s2) {
                HStack {
                    Spacer(minLength: 0)
                    Text("▸")
                        .font(Typography.mono(Typography.Size.md, weight: .bold))
                        .foregroundStyle(.white)
                        .opacity(Opacities.muted)
                }
                Spacer(minLength: 0)
                Text(caption ?? "video")
                    .font(Typography.sansBold(Typography.Size.sm))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)
            }
            .padding(.leading, inset.leading)
            .padding(.trailing, inset.trailing)
            .padding(.top, inset.top)
            .padding(.bottom, inset.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .accessibilityLabel(caption ?? "Video from the feed")
    }

    @ViewBuilder
    private var artwork: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .widgetFullColor()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            theme.background
        }
    }

    private var inset: EdgeInsets {
        EdgeInsets(
            top: max(systemMargins.top, 12),
            leading: max(systemMargins.leading, 12),
            bottom: max(systemMargins.bottom, 10),
            trailing: max(systemMargins.trailing, 12)
        )
    }
}

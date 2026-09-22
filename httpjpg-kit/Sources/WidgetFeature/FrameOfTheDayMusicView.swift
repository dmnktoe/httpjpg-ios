import SwiftUI
import Tokens
import WidgetKit

struct FrameOfTheDayMusicView: View {
    let title: String
    let artist: String?
    let artwork: UIImage?
    let actionURL: URL?
    let playsInApp: Bool

    @Environment(\.pageTheme) private var theme
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetContentMargins) private var systemMargins

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            header
            Spacer(minLength: 0)
            titles
            if let actionURL {
                Link(destination: actionURL) {
                    playLabel
                }
                .accessibilityLabel(playsInApp ? "Play \(title)" : "Listen to \(title)")
            }
        }
        .padding(.leading, inset.leading)
        .padding(.trailing, inset.trailing)
        .padding(.top, inset.top)
        .padding(.bottom, inset.bottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: Spacing.s2) {
            if let artwork {
                Image(uiImage: artwork)
                    .resizable()
                    .scaledToFill()
                    .frame(width: artworkSize, height: artworkSize)
                    .clipped()
                    .overlay(Rectangle().stroke(theme.border, lineWidth: 1))
            }
            Spacer(minLength: 0)
            Text("♪")
                .font(Typography.mono(Typography.Size.sm))
                .opacity(Opacities.muted)
        }
    }

    private var titles: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Typography.sansBold(family == .systemSmall ? Typography.Size.sm : Typography.Size.md))
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            if let artist, !artist.isEmpty {
                Text(artist)
                    .font(Typography.mono(Typography.Size.xs))
                    .opacity(Opacities.muted)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var playLabel: some View {
        Text(playsInApp ? "▸ PLAY" : "▸ LISTEN")
            .font(Typography.mono(Typography.Size.sm, weight: .bold))
            .padding(.horizontal, Spacing.s3)
            .padding(.vertical, Spacing.s2)
            .overlay(Rectangle().stroke(theme.foreground, lineWidth: 1))
            .contentShape(Rectangle())
    }

    private var artworkSize: CGFloat {
        family == .systemSmall ? 48 : 64
    }

    private var inset: EdgeInsets {
        EdgeInsets(
            top: max(systemMargins.top, 12),
            leading: max(systemMargins.leading, 12),
            bottom: max(systemMargins.bottom, 12),
            trailing: max(systemMargins.trailing, 12)
        )
    }
}

import AVKit
import DesignSystem
import SwiftUI

/// Renders the `video` blok.
///
/// Direct asset URLs play inline with `AVPlayer`. Vimeo and YouTube do not
/// hand out playable streams, and embedding their web players inside a
/// `WKWebView` would drag their tracking into the app — those become a card
/// that hands off to the system player or browser, which is also where the
/// user's cookie choice on the web already points.
public struct SbVideoView: View {
    private let blok: VideoBlok

    @Environment(\.openURL) private var openURL
    @Environment(\.pageTheme) private var theme

    public init(blok: VideoBlok) {
        self.blok = blok
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            player
            if blok.caption != nil {
                StoryRichText(blok.caption, size: Typography.Size.xs)
                    .opacity(Opacities.muted)
            }
        }
        .blokSpacing(blok.spacing)
    }

    @ViewBuilder
    private var player: some View {
        if let url = blok.assetURL {
            VideoPlayer(player: AVPlayer(url: url))
                .aspectRatio(blok.aspectRatio ?? 16.0 / 9.0, contentMode: .fit)
        } else if let url = blok.externalURL {
            Button {
                openURL(url)
            } label: {
                handoff(host: url.host ?? "video")
            }
            .buttonStyle(.plain)
        }
    }

    private func handoff(host: String) -> some View {
        VStack(spacing: Spacing.s3) {
            MonoText("▸ watch on \(host)", size: Typography.Size.sm)
            MonoText(Ascii.tape, size: Typography.Size.xxs, opacity: Opacities.tape)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(blok.aspectRatio ?? 16.0 / 9.0, contentMode: .fit)
        .overlay(Rectangle().stroke(theme.border, lineWidth: 1))
        .contentShape(Rectangle())
    }
}

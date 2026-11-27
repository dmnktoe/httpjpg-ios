import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

struct FeedGridCell: View {
    let post: FeedPost

    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.displayScale) private var displayScale

    private static let columns: CGFloat = 3

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay { cover }
            .clipped()
            .overlay(alignment: .topTrailing) {
                if let badge {
                    Image(systemName: badge)
                        .font(Typography.mono(Typography.Size.sm))
                        .foregroundStyle(Palette.white)
                        .shadow(color: Palette.black.opacity(0.4), radius: 2)
                        .padding(Spacing.s2)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(post.blok.caption ?? "Post")
            .accessibilityAddTraits(.isButton)
    }

    private var badge: String? {
        if post.blok.images.count > 1 { return "square.on.square.fill" }
        if post.blok.images.first?.videoURL != nil { return "play.fill" }
        if post.blok.images.isEmpty, post.blok.music != nil { return "music.note" }
        return nil
    }

    private var tileWidth: CGFloat {
        viewportWidth / Self.columns
    }

    @ViewBuilder
    private var cover: some View {
        if let image = post.blok.images.first {
            if let videoURL = image.videoURL {
                LoopingVideoPlayer(url: videoURL, aspectRatio: 1, fills: true)
            } else {
                RemoteImage(
                    url: URL(string: ImageService.Preset.width(
                        image.filename,
                        tileWidth,
                        scale: displayScale,
                        focus: image.image?.focus ?? ""
                    )),
                    aspectRatio: 1,
                    contentMode: .fill,
                    animated: image.image?.isGIF ?? false
                )
            }
        } else if let artwork = post.blok.music?.artworkURL, !artwork.isEmpty {
            RemoteImage(
                url: URL(string: ImageService.Preset.square(artwork, points: tileWidth, scale: displayScale)),
                aspectRatio: 1,
                contentMode: .fill
            )
        } else {
            FeedTrackTile(
                title: post.blok.music?.title ?? post.blok.music?.headerText ?? "untitled",
                artist: post.blok.music?.artist ?? post.blok.music?.footerText
            )
        }
    }
}

import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

struct FeedGridCell: View {
    let post: FeedPost

    @Environment(\.pageTheme) private var theme
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
        return nil
    }

    @ViewBuilder
    private var cover: some View {
        if let image = post.blok.images.first, image.videoURL == nil {
            RemoteImage(
                url: URL(string: ImageService.Preset.width(
                    image.filename,
                    viewportWidth / Self.columns,
                    scale: displayScale,
                    focus: image.image?.focus ?? ""
                )),
                aspectRatio: 1,
                contentMode: .fill,
                animated: image.image?.isGIF ?? false
            )
        } else {
            theme.border
                .overlay {
                    Text(post.blok.images.isEmpty ? "♪" : "▶")
                        .font(Typography.mono(Typography.Size.xl))
                        .foregroundStyle(theme.foreground)
                }
        }
    }
}

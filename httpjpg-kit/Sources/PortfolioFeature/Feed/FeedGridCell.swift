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
                if post.blok.images.count > 1 {
                    Image(systemName: "square.on.square.fill")
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

    @ViewBuilder
    private var cover: some View {
        if let image = post.blok.images.first {
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
                    Text("♪")
                        .font(Typography.mono(Typography.Size.xl))
                        .foregroundStyle(theme.foreground)
                }
        }
    }
}

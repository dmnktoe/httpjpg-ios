import DesignSystem
import StoryblokContent
import StoryblokCore
import SwiftUI
import Tokens

struct FeedPostView: View {
    let post: FeedPost

    /// Set when the post is one tile of the feed grid: the frame turns square,
    /// the caption clamps to two lines, and images are fetched for the tile.
    var tileWidth: CGFloat?

    @Environment(\.pageTheme) private var theme
    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.displayScale) private var displayScale

    @State private var index = 0
    @State private var isZoomed = false

    private var images: [PostImageBlok] { post.blok.images }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            if !images.isEmpty {
                frame
            }
            if let music = post.blok.music {
                SbMusicPlayerView(blok: music)
            }
            if let caption = post.blok.caption, !caption.isEmpty {
                Text(caption)
                    .font(Typography.sans(Typography.Size.md))
                    .lineLimit(isTile ? 2 : nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, textInset)
            }
            if let date = post.blok.dateLabel {
                MonoText(date, size: Typography.Size.xs, opacity: Opacities.muted)
                    .padding(.horizontal, textInset)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var frame: some View {
        TabView(selection: $index) {
            ForEach(Array(images.enumerated()), id: \.element.id) { offset, image in
                slide(image)
                    .tag(offset)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .aspectRatio(frameAspectRatio, contentMode: .fit)
        .background(theme.background)
        .overlay(alignment: .bottomTrailing) {
            if images.count > 1 {
                counter
            }
        }
        .onTapGesture { isZoomed = true }
        .fullScreenCover(isPresented: $isZoomed) {
            ImageZoomViewer(
                url: fullURL(images[min(index, images.count - 1)]),
                accessibilityText: images[min(index, images.count - 1)].accessibilityText,
                animated: images[min(index, images.count - 1)].image?.isGIF ?? false
            )
        }
    }

    private func slide(_ image: PostImageBlok) -> some View {
        RemoteImage(
            url: frameURL(image),
            aspectRatio: frameAspectRatio,
            contentMode: image.fit == .contain ? .fit : .fill,
            accessibilityText: image.accessibilityText,
            animated: image.image?.isGIF ?? false
        )
    }

    private var counter: some View {
        Text("[ \(Self.pad(index + 1)) / \(Self.pad(images.count)) ]")
            .font(Typography.mono(Typography.Size.xs))
            .foregroundStyle(Palette.white)
            .padding(.horizontal, Spacing.s2)
            .padding(.vertical, Spacing.s1)
            .background(Palette.black.opacity(0.55))
            .padding(Spacing.s2)
            .accessibilityHidden(true)
    }

    private func frameURL(_ image: PostImageBlok) -> URL? {
        URL(string: ImageService.Preset.width(
            image.filename,
            tileWidth ?? viewportWidth,
            scale: displayScale,
            focus: image.image?.focus ?? ""
        ))
    }

    private func fullURL(_ image: PostImageBlok) -> URL? {
        URL(string: ImageService.processed(image.filename, crop: "2560x0"))
    }

    private var isTile: Bool { tileWidth != nil }

    private var frameAspectRatio: CGFloat {
        isTile ? 1 : post.blok.aspectRatio
    }

    // A tile already sits inside the grid's gutter; the full-bleed stream
    // insets its text on its own.
    private var textInset: CGFloat {
        isTile ? 0 : PageLayout.gutter
    }

    private static func pad(_ value: Int) -> String {
        value < 10 ? "0\(value)" : String(value)
    }
}

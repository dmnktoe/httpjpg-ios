import DesignSystem
import StoryblokContent
import StoryblokCore
import SwiftUI
import Tokens

struct FeedPostView: View {
    let post: FeedPost

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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, PageLayout.gutter)
            }
            if let date = post.blok.dateLabel {
                MonoText(date, size: Typography.Size.xs, opacity: Opacities.muted)
                    .padding(.horizontal, PageLayout.gutter)
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
        .aspectRatio(post.blok.aspectRatio, contentMode: .fit)
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
            aspectRatio: post.blok.aspectRatio,
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
            viewportWidth,
            scale: displayScale,
            focus: image.image?.focus ?? ""
        ))
    }

    private func fullURL(_ image: PostImageBlok) -> URL? {
        URL(string: ImageService.processed(image.filename, crop: "2560x0"))
    }

    private static func pad(_ value: Int) -> String {
        value < 10 ? "0\(value)" : String(value)
    }
}

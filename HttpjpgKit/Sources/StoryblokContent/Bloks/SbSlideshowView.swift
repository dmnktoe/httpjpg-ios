import DesignSystem
import SwiftUI

public struct SbSlideshowView: View {
    private let blok: SlideshowBlok

    public init(blok: SlideshowBlok) {
        self.blok = blok
    }

    public var body: some View {
        if !blok.images.isEmpty {
            ImageCarousel(
                count: blok.images.count,
                aspectRatio: aspectRatio,
                autoplayInterval: 7,
                showsCounter: blok.showsCounter
            ) { position in
                slide(blok.images[position])
            }
            .blokSpacing(blok.spacing)
        }
    }

    @ViewBuilder
    private func slide(_ asset: StoryblokAsset) -> some View {
        if asset.isVideo, let filename = asset.filename, let url = URL(string: filename) {
            LoopingVideoPlayer(url: url, aspectRatio: aspectRatio)
        } else {
            AssetImage(asset: asset, aspectRatio: aspectRatio)
        }
    }

    private var aspectRatio: CGFloat {
        blok.aspectRatio ?? PageLayout.mediaAspectRatio
    }
}

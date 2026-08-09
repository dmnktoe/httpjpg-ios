import DesignSystem
import SwiftUI

public struct SbSlideshowView: View {
    private let blok: SlideshowBlok

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(blok: SlideshowBlok) {
        self.blok = blok
    }

    public var body: some View {
        if !blok.images.isEmpty {
            ImageCarousel(
                count: blok.images.count,
                aspectRatio: aspectRatio,
                autoplayInterval: 7,
                showsCounter: blok.showsCounter,
                ownsRotation: { blok.images[$0].isVideo }
            ) { position in
                slide(blok.images[position])
            }
            .blokSpacing(blok.spacing)
        }
    }

    @ViewBuilder
    private func slide(_ asset: StoryblokAsset) -> some View {
        if asset.isVideo, let filename = asset.filename, let url = URL(string: filename) {
            SlideshowVideo(url: url, aspectRatio: aspectRatio, playsThrough: playsThrough)
        } else {
            AssetImage(asset: asset, aspectRatio: aspectRatio)
        }
    }

    /// A clip only takes over the rotation when there is a rotation to take
    /// over. A single slide has nowhere to advance to, and under reduced motion
    /// autoplay is off anyway — both keep the plain loop.
    private var playsThrough: Bool {
        blok.images.count > 1 && !reduceMotion
    }

    private var aspectRatio: CGFloat {
        blok.aspectRatio ?? PageLayout.mediaAspectRatio
    }
}

private struct SlideshowVideo: View {
    let url: URL
    let aspectRatio: CGFloat
    let playsThrough: Bool

    @Environment(\.carouselSlide) private var slide

    var body: some View {
        LoopingVideoPlayer(
            url: url,
            aspectRatio: aspectRatio,
            isActive: slide.isActive,
            onFinished: playsThrough ? slide.advance : nil
        )
    }
}

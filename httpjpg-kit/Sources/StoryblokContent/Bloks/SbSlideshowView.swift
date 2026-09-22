import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

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
                autoplayInterval: autoplayInterval,
                transitionDuration: blok.transitionSpeed,
                showsArrows: blok.showsNavigation,
                showsCounter: blok.showsCounter,
                usesFadeTransition: blok.effect == "fade",
                ownsRotation: { blok.images[$0].isVideo }
            ) { position, context in
                slide(blok.images[position], context)
            }
            .blokSpacing(blok.spacing)
        }
    }

    @ViewBuilder
    private func slide(_ asset: StoryblokAsset, _ context: CarouselSlide) -> some View {
        Group {
            if asset.isVideo, let filename = asset.filename, let url = URL(string: filename) {
                LoopingVideoPlayer(
                    url: url,
                    aspectRatio: aspectRatio,
                    isActive: context.isActive,
                    onFinished: playsThrough ? context.advance : nil
                )
            } else {
                AssetImage(
                    asset: asset,
                    aspectRatio: aspectRatio,
                    opensLightbox: false,
                    overlayPattern: blok.overlay,
                    overlayInset: blok.overlayInset
                )
            }
        }
    }

    private var playsThrough: Bool {
        blok.images.count > 1 && !reduceMotion
    }

    private var aspectRatio: CGFloat {
        blok.aspectRatio ?? PageLayout.mediaAspectRatio
    }

    private var autoplayInterval: TimeInterval? {
        blok.autoplayDelay > 0 ? blok.autoplayDelay : nil
    }
}

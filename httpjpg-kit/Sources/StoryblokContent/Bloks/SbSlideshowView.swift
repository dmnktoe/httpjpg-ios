import DesignSystem
import StoryblokCore
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
                ownsRotation: { blok.images[$0].isVideo && playsThrough }
            ) { position, context in
                slide(blok.images[position], context)
            }
            .blokSpacing(blok.spacing)
        }
    }

    @ViewBuilder
    private func slide(_ asset: StoryblokAsset, _ context: CarouselSlide) -> some View {
        if asset.isVideo, let filename = asset.filename, let url = URL(string: filename) {
            LoopingVideoPlayer(
                url: url,
                aspectRatio: aspectRatio,
                isActive: context.isActive,
                onFinished: playsThrough ? context.advance : nil
            )
        } else {
            AssetImage(asset: asset, aspectRatio: aspectRatio)
        }
    }

    /// A video slide hands the carousel back when it ends. It cannot when it
    /// never plays, so the timer has to keep the rotation in those cases.
    private var playsThrough: Bool {
        blok.images.count > 1 && !reduceMotion && !LowPowerMode.shared.isEnabled
    }

    private var aspectRatio: CGFloat {
        blok.aspectRatio ?? PageLayout.mediaAspectRatio
    }
}

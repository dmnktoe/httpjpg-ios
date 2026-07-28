import DesignSystem
import SwiftUI

/// Renders the `slideshow` blok on the shared ``ImageCarousel`` — with the
/// exact same playback the work cards use. Arrows always on, the same 7-second
/// autoplay, the same transition; only `showCounter` and the aspect ratio come
/// from the CMS. One carousel, one behaviour, everywhere.
///
/// Video assets become chromeless muted loops, the same thing the web's
/// `<video autoplay muted loop>` slide is.
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

    /// One carousel needs one height, and it is a declared one — the CMS ratio
    /// if set, the house ratio otherwise. Reading it off the first asset made
    /// the box change from slideshow to slideshow down a page.
    private var aspectRatio: CGFloat {
        blok.aspectRatio ?? PageLayout.mediaAspectRatio
    }
}


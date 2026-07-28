import DesignSystem
import SwiftUI

/// Renders the `slideshow` blok on the shared ``ImageCarousel``.
///
/// The CMS config comes across field for field: `autoplayDelay` drives the
/// loop, `speed` the transition, `showNavigation` the arrows, `showCounter`
/// the `01/04` strip. The carousel itself — including why autoplay is a task
/// and not a timer — lives in `DesignSystem`, shared with the work cards.
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
                autoplayInterval: blok.autoplayInterval,
                transitionDuration: blok.transitionDuration,
                showsArrows: blok.showsNavigation,
                showsCounter: blok.showsCounter
            ) { position in
                AssetImage(asset: blok.images[position], aspectRatio: aspectRatio)
            }
            .blokSpacing(blok.spacing)
        }
    }

    /// One carousel needs one height, and it is a declared one — the CMS ratio
    /// if set, the house ratio otherwise. Reading it off the first asset made
    /// the box change from slideshow to slideshow down a page.
    private var aspectRatio: CGFloat {
        blok.aspectRatio ?? PageLayout.mediaAspectRatio
    }
}

import AVKit
import DesignSystem
import SwiftUI

/// Renders the `slideshow` blok on the shared ``ImageCarousel``.
///
/// The CMS config comes across field for field: `autoplayDelay` drives the
/// loop, `speed` the transition, `showNavigation` the arrows, `showCounter`
/// the `01/04` strip. The carousel itself — including why autoplay is a task
/// and not a timer — lives in `DesignSystem`, shared with the work cards.
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
                autoplayInterval: blok.autoplayInterval,
                transitionDuration: blok.transitionDuration,
                showsArrows: blok.showsNavigation,
                showsCounter: blok.showsCounter
            ) { position in
                slide(blok.images[position])
            }
            .blokSpacing(blok.spacing)
        }
    }

    @ViewBuilder
    private func slide(_ asset: StoryblokAsset) -> some View {
        if asset.isVideo {
            SlideshowVideoSlide(asset: asset, aspectRatio: aspectRatio)
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

/// A clip inside a slideshow: muted, looping, no chrome.
///
/// `allowsHitTesting(false)` is what keeps it chromeless — `VideoPlayer` only
/// shows its controls on touch, and the touches go to the carousel instead.
/// Muted playback shares the audio session politely, so a running music track
/// keeps playing over it.
private struct SlideshowVideoSlide: View {
    let asset: StoryblokAsset
    /// A player view has no intrinsic size — without this box a lone video
    /// slide laid out at zero height and simply never appeared.
    let aspectRatio: CGFloat

    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?

    var body: some View {
        Color.black
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay {
                if let player {
                    VideoPlayer(player: player)
                        .allowsHitTesting(false)
                }
            }
            .clipped()
            .onAppear(perform: start)
            .onDisappear { player?.pause() }
            .accessibilityHidden(true)
    }

    private func start() {
        if player == nil {
            guard let filename = asset.filename, let url = URL(string: filename) else { return }
            let queue = AVQueuePlayer()
            queue.isMuted = true
            looper = AVPlayerLooper(player: queue, templateItem: AVPlayerItem(url: url))
            player = queue
        }
        player?.play()
    }
}

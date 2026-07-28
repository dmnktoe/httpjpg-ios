import DesignSystem
import SwiftUI

/// Renders the `slideshow` blok.
///
/// The web autoplays with a Ken Burns-style zoom. Here it is a paged carousel:
/// autoplay on a phone competes with scrolling for attention, and a swipe is
/// how people expect to move through images on a touch screen.
public struct SbSlideshowView: View {
    private let blok: SlideshowBlok

    @Environment(\.viewportWidth) private var viewportWidth

    public init(blok: SlideshowBlok) {
        self.blok = blok
    }

    public var body: some View {
        if !blok.images.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                TabView {
                    ForEach(Array(blok.images.enumerated()), id: \.offset) { entry in
                        AssetImage(asset: entry.element, aspectRatio: aspectRatio)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: blok.images.count > 1 ? .automatic : .never))
                .frame(height: PageLayout.cardWidth(viewport: viewportWidth) / aspectRatio)

                if blok.showsCounter, blok.images.count > 1 {
                    MonoText(
                        "01/\(String(format: "%02d", blok.images.count))  \(Ascii.tape)",
                        size: Typography.Size.xxs,
                        opacity: Opacities.subtle
                    )
                    .lineLimit(1)
                }
            }
            .blokSpacing(blok.spacing)
        }
    }

    /// One carousel needs one height. The CMS ratio wins; otherwise the first
    /// image's own proportions do, so the common case of a uniform set looks
    /// right without anyone configuring it.
    private var aspectRatio: CGFloat {
        blok.aspectRatio
            ?? ImageService.aspectRatio(of: blok.images.first?.filename)
            ?? 16.0 / 9.0
    }
}

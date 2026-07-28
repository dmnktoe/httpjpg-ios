import DesignSystem
import SwiftUI

/// Renders the `image` blok, caption included — at the size the CMS asked
/// for. The blok's `width` option (`"5%"` for a logo, `"50%"` for a banner)
/// scales the box; the declared aspect ratio wins when set and the asset's
/// natural proportions apply otherwise, which is exactly `widthCss` plus the
/// web `<Image>`'s behaviour. Forcing every blok to the house ratio turned a
/// square logo into a full-bleed 16:9 crop of the letter R.
public struct SbImageView: View {
    private let blok: ImageBlok

    @Environment(\.viewportWidth) private var viewportWidth

    public init(blok: ImageBlok) {
        self.blok = blok
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            if let asset = blok.image, !asset.isEmpty {
                AssetImage(
                    asset: asset,
                    fallbackAlt: blok.alt ?? "",
                    aspectRatio: AspectRatio.parse(blok.aspectRatio),
                    copyrightPosition: blok.copyrightPosition
                )
                .frame(width: configuredWidth)
            }
            if blok.caption != nil {
                StoryRichText(blok.caption, size: Typography.Size.sm)
                    .opacity(Opacities.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // `SbImage` on the web carries `mb: "4"` before its spacing matrix is
        // applied — the one default gap in the whole blok system. The CMS still
        // wins: an explicit `mb` overrides it, including `mb: 0`.
        .padding(.bottom, blok.spacing.marginBottom == nil ? Spacing.s4 : 0)
        .blokSpacing(blok.spacing)
    }

    /// The CMS width fraction against the content column; `nil` (full width)
    /// leaves the frame unconstrained.
    private var configuredWidth: CGFloat? {
        blok.widthFraction.map { PageLayout.cardWidth(viewport: viewportWidth) * $0 }
    }
}

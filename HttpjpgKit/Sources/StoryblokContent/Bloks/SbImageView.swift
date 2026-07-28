import DesignSystem
import SwiftUI

/// Renders the `image` blok, caption included.
public struct SbImageView: View {
    private let blok: ImageBlok

    public init(blok: ImageBlok) {
        self.blok = blok
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            if let asset = blok.image, !asset.isEmpty {
                AssetImage(
                    asset: asset,
                    fallbackAlt: blok.alt ?? "",
                    aspectRatio: ratio,
                    copyrightPosition: blok.copyrightPosition
                )
            }
            if blok.caption != nil {
                StoryRichText(blok.caption, size: Typography.Size.sm)
                    .opacity(Opacities.muted)
            }
        }
        // `SbImage` on the web carries `mb: "4"` before its spacing matrix is
        // applied — the one default gap in the whole blok system. The CMS still
        // wins: an explicit `mb` overrides it, including `mb: 0`.
        .padding(.bottom, blok.spacing.marginBottom == nil ? Spacing.s4 : 0)
        .blokSpacing(blok.spacing)
    }

    /// A declared ratio, never the asset's own. The CMS sets `16/9` on most
    /// images and leaves the rest empty; sizing those to whatever the file
    /// happens to be made the page scroll in lurches.
    private var ratio: CGFloat {
        AspectRatio.parse(blok.aspectRatio) ?? PageLayout.mediaAspectRatio
    }
}

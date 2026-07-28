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
                    aspectRatio: ratio
                )
            }
            if blok.caption != nil {
                StoryRichText(blok.caption, size: Typography.Size.sm)
                    .opacity(Opacities.muted)
            }
        }
        .blokSpacing(blok.spacing)
    }

    /// `nil` means "let the image decide", which is what `auto` and an empty
    /// field both mean in the CMS.
    private var ratio: CGFloat? {
        AspectRatio.parse(blok.aspectRatio)
    }
}

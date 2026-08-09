import DesignSystem
import StoryblokCore
import SwiftUI

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

        .padding(.bottom, blok.spacing.marginBottom == nil ? Spacing.s4 : 0)
        .blokSpacing(blok.spacing)
    }

    private var configuredWidth: CGFloat? {
        blok.widthFraction.map { PageLayout.cardWidth(viewport: viewportWidth) * $0 }
    }
}

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

    /// Storyblok stores aspect ratios as `"16/9"`, `"4/3"`, `"1/1"`, … or
    /// `"auto"`, which means "let the image decide".
    private var ratio: CGFloat? {
        guard let raw = blok.aspectRatio, raw != "auto" else { return nil }
        let parts = raw.split(separator: "/")
        guard parts.count == 2,
              let width = Double(parts[0]),
              let height = Double(parts[1]),
              height != 0
        else { return nil }
        return CGFloat(width / height)
    }
}

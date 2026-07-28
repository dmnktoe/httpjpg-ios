import DesignSystem
import SwiftUI

/// A Storyblok asset rendered at the size the device will actually draw it,
/// and at the proportions the asset actually has.
///
/// This is the app's answer to `srcSet`/`sizes` on the web: the request width
/// is the layout width times the display scale, so a 3× phone never downloads
/// a 1× image and never a desktop-sized one either.
public struct AssetImage: View {
    private let asset: StoryblokAsset
    private let fallbackAlt: String
    private let aspectRatioOverride: CGFloat?
    private let contentMode: ContentMode

    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.displayScale) private var displayScale

    /// - Parameter aspectRatio: Overrides the asset's own proportions. Leave
    ///   `nil` unless the CMS explicitly asks for a crop — the natural ratio
    ///   read from the URL is almost always the right answer.
    public init(
        asset: StoryblokAsset,
        fallbackAlt: String = "",
        aspectRatio: CGFloat? = nil,
        contentMode: ContentMode = .fill
    ) {
        self.asset = asset
        self.fallbackAlt = fallbackAlt
        self.aspectRatioOverride = aspectRatio
        self.contentMode = contentMode
    }

    public var body: some View {
        RemoteImage(
            url: URL(string: ImageService.Preset.width(
                asset.filename,
                PageLayout.cardWidth(viewport: viewportWidth),
                scale: displayScale,
                focus: asset.focus ?? ""
            )),
            placeholderURL: URL(string: ImageService.Preset.blur(asset.filename, focus: asset.focus ?? "")),
            aspectRatio: aspectRatioOverride ?? ImageService.aspectRatio(of: asset.filename),
            contentMode: contentMode,
            accessibilityText: asset.accessibilityText(fallback: fallbackAlt)
        )
    }
}

import SwiftUI

/// Async image with a low-res blur placeholder — the Swift counterpart of
/// `@httpjpg/ui`'s `<Image>` with `blurOnLoad`.
///
/// The layout is driven by a transparent spacer at the target aspect ratio,
/// with the image drawn as an overlay on top. That keeps the view's height
/// deterministic before the image arrives — the alternative, letting a loaded
/// `Image` size itself, makes rows jump as each asset lands and stacks them
/// unpredictably inside a `ScrollView`.
///
/// Callers pass URLs already transformed by the Storyblok image service; this
/// view knows nothing about Storyblok itself.
public struct RemoteImage: View {
    private let url: URL?
    private let placeholderURL: URL?
    private let aspectRatio: CGFloat
    private let contentMode: ContentMode
    private let accessibilityText: String?

    @Environment(\.pageTheme) private var theme

    /// - Parameter aspectRatio: Width ÷ height. Pass the asset's real ratio —
    ///   `ImageService.aspectRatio(of:)` reads it out of the Storyblok URL —
    ///   rather than relying on the 3:2 default.
    public init(
        url: URL?,
        placeholderURL: URL? = nil,
        aspectRatio: CGFloat? = nil,
        contentMode: ContentMode = .fill,
        accessibilityText: String? = nil
    ) {
        self.url = url
        self.placeholderURL = placeholderURL
        self.aspectRatio = aspectRatio ?? 3.0 / 2.0
        self.contentMode = contentMode
        self.accessibilityText = accessibilityText
    }

    public var body: some View {
        Color.clear
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay { image }
            .clipped()
            // `clipped()` trims pixels, not hit testing: a filled image
            // overflows its box, and the invisible overflow stole taps from
            // whatever sat above or below the card — tapping the work filter
            // opened the first story. The contentShape pins the tappable
            // region to the visible box.
            .contentShape(Rectangle())
            .accessibilityLabel(accessibilityText ?? "")
            .accessibilityHidden(accessibilityText == nil)
    }

    @ViewBuilder
    private var image: some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.35))) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            case .failure:
                placeholder(showsGlyph: true)
            case .empty:
                blurPlaceholder
            @unknown default:
                placeholder(showsGlyph: false)
            }
        }
    }

    @ViewBuilder
    private var blurPlaceholder: some View {
        if let placeholderURL {
            AsyncImage(url: placeholderURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .blur(radius: 8)
            } placeholder: {
                placeholder(showsGlyph: false)
            }
        } else {
            placeholder(showsGlyph: false)
        }
    }

    private func placeholder(showsGlyph: Bool) -> some View {
        theme.border.opacity(0.35)
            .overlay(alignment: .center) {
                if showsGlyph {
                    AsciiArt(Ascii.offline, label: "Image unavailable", size: Typography.Size.xxs, opacity: 0.6)
                }
            }
    }
}

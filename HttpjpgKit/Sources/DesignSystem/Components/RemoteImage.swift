import SwiftUI

/// Async image with a low-res blur placeholder — the Swift counterpart of
/// `@httpjpg/ui`'s `<Image>` with `blurOnLoad`.
///
/// Callers pass both URLs already transformed by the Storyblok image service;
/// this view knows nothing about Storyblok itself.
public struct RemoteImage: View {
    private let url: URL?
    private let placeholderURL: URL?
    private let aspectRatio: CGFloat?
    private let contentMode: ContentMode
    private let accessibilityText: String?

    @Environment(\.pageTheme) private var theme

    public init(
        url: URL?,
        placeholderURL: URL? = nil,
        aspectRatio: CGFloat? = nil,
        contentMode: ContentMode = .fill,
        accessibilityText: String? = nil
    ) {
        self.url = url
        self.placeholderURL = placeholderURL
        self.aspectRatio = aspectRatio
        self.contentMode = contentMode
        self.accessibilityText = accessibilityText
    }

    public var body: some View {
        content
            .modifier(AspectRatioModifier(ratio: aspectRatio, contentMode: contentMode))
            .clipped()
            .accessibilityLabel(accessibilityText ?? "")
            .accessibilityHidden(accessibilityText == nil)
    }

    @ViewBuilder
    private var content: some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.35))) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity)
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

/// Applies a fixed aspect ratio when one is known, and otherwise leaves the
/// image to size itself — Storyblok assets don't always carry dimensions.
private struct AspectRatioModifier: ViewModifier {
    let ratio: CGFloat?
    let contentMode: ContentMode

    func body(content: Content) -> some View {
        if let ratio {
            content.aspectRatio(ratio, contentMode: contentMode)
        } else {
            content
        }
    }
}

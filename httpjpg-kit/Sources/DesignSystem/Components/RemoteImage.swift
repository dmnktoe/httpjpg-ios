import SwiftUI
import Tokens

public struct RemoteImage: View {
    private let url: URL?
    private let placeholderURL: URL?
    private let aspectRatio: CGFloat
    private let contentMode: ContentMode
    private let accessibilityText: String?
    private let animated: Bool

    @Environment(\.pageTheme) private var theme

    public init(
        url: URL?,
        placeholderURL: URL? = nil,
        aspectRatio: CGFloat? = nil,
        contentMode: ContentMode = .fill,
        accessibilityText: String? = nil,
        animated: Bool = false
    ) {
        self.url = url
        self.placeholderURL = placeholderURL
        self.aspectRatio = aspectRatio ?? 3.0 / 2.0
        self.contentMode = contentMode
        self.accessibilityText = accessibilityText
        self.animated = animated
    }

    public var body: some View {
        Color.clear
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay { image }
            .clipped()

            .contentShape(Rectangle())
            .accessibilityLabel(accessibilityText ?? "")
            .accessibilityHidden(accessibilityText == nil)
    }

    @ViewBuilder
    private var image: some View {
        if animated {
            ZStack {
                blurPlaceholder
                AnimatedGIFView(url: url, contentMode: contentMode)
            }
        } else {
            AsyncImage(url: url, transaction: Transaction(animation: Motion.mediaIn)) { phase in
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

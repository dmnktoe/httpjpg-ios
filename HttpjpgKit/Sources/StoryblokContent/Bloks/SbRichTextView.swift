import DesignSystem
import RichTextView
import StoryblokClient
import SwiftUI

/// Renders the `richtext` blok.
///
/// The document itself is rendered by the SDK's `RichTextView`, which is
/// available because ``PortfolioBlok`` conforms to `View` — embedded bloks
/// therefore render inline alongside the standard nodes.
public struct SbRichTextView: View {
    private let blok: RichTextBlok

    @Environment(\.pageTheme) private var theme

    public init(blok: RichTextBlok) {
        self.blok = blok
    }

    public var body: some View {
        Group {
            if let content = blok.content {
                content
            }
        }
        .font(Typography.sans(Typography.Size.md))
        .foregroundStyle(Palette.named(blok.color) ?? theme.foreground)
        .frame(maxWidth: .infinity, alignment: .leading)
        .blokSpacing(blok.spacing)
    }
}

/// Renders a bare rich-text document, for fields that are not their own blok
/// (a work story's `description`, an image caption).
public struct StoryRichText: View {
    private let document: RichText<PortfolioBlok>?
    private let size: CGFloat

    public init(_ document: RichText<PortfolioBlok>?, size: CGFloat = Typography.Size.md) {
        self.document = document
        self.size = size
    }

    public var body: some View {
        if let document {
            document
                .font(Typography.sans(size))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

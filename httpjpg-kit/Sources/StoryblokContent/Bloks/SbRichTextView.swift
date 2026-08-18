import StoryblokCore
import SwiftUI
import Tokens

public struct SbRichTextView: View {
    private let blok: RichTextBlok

    @Environment(\.pageTheme) private var theme

    public init(blok: RichTextBlok) {
        self.blok = blok
    }

    public var body: some View {
        StoryRichText(blok.content, color: Palette.named(blok.color))
            .foregroundStyle(Palette.named(blok.color) ?? theme.foreground)
            .blokSpacing(blok.spacing)
    }
}

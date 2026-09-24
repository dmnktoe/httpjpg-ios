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
        let proseCap = BlokProseMaxWidth.maxWidthPoints(for: blok.maxWidth)
        StoryRichText(blok.content, color: Palette.named(blok.color))
            .foregroundStyle(Palette.named(blok.color) ?? theme.foreground)
            .frame(maxWidth: proseCap ?? .infinity, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .blokSpacing(blok.spacing)
    }
}

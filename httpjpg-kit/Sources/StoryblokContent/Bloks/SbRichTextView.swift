import DesignSystem
import StoryblokCore
import SwiftUI

public struct SbRichTextView: View {
    private let blok: RichTextBlok

    @Environment(\.pageTheme) private var theme

    public init(blok: RichTextBlok) {
        self.blok = blok
    }

    public var body: some View {
        StoryRichText(blok.content)
            .foregroundStyle(Palette.named(blok.color) ?? theme.foreground)
            .blokSpacing(blok.spacing)
    }
}

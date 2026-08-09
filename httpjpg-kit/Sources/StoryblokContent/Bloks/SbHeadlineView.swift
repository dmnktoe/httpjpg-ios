import DesignSystem
import StoryblokCore
import SwiftUI

public struct SbHeadlineView: View {
    private let blok: HeadlineBlok

    @Environment(\.pageTheme) private var theme

    public init(blok: HeadlineBlok) {
        self.blok = blok
    }

    public var body: some View {
        Headline(
            blok.text,
            level: Headline.Level(rawValue: blok.level) ?? .two,
            alignment: TextAlignment(cmsAlign: blok.align)
        )
        .foregroundStyle(Palette.named(blok.color) ?? theme.foreground)
        .blokSpacing(blok.spacing)
    }
}

extension TextAlignment {
    init(cmsAlign: String?) {
        switch cmsAlign {
        case "center": self = .center
        case "right": self = .trailing
        default: self = .leading
        }
    }
}

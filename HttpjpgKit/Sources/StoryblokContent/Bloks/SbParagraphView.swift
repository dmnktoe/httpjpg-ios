import DesignSystem
import SwiftUI

public struct SbParagraphView: View {
    private let blok: ParagraphBlok

    @Environment(\.pageTheme) private var theme

    public init(blok: ParagraphBlok) {
        self.blok = blok
    }

    public var body: some View {
        BodyText(
            blok.text,
            size: BodyText.Size(cmsSize: blok.size),
            weight: Font.Weight(cmsWeight: blok.weight),
            alignment: TextAlignment(cmsAlign: blok.align)
        )
        .foregroundStyle(Palette.named(blok.color) ?? theme.foreground)
        .blokSpacing(blok.spacing)
    }
}

extension BodyText.Size {
    init(cmsSize: String?) {
        switch cmsSize {
        case "md": self = .md
        case "lg": self = .lg
        case "xl", "base": self = .xl
        default: self = .sm
        }
    }
}

extension Font.Weight {
    init(cmsWeight: String?) {
        switch cmsWeight {
        case "medium": self = .medium
        case "semibold": self = .semibold
        case "bold", "extrabold", "black": self = .bold
        case "light", "extralight", "thin": self = .light
        default: self = .regular
        }
    }
}

import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

public struct SbDividerView: View {
    private let blok: DividerBlok

    public init(blok: DividerBlok) {
        self.blok = blok
    }

    public var body: some View {
        BrutalDivider(
            variant: BrutalDivider.Variant(rawValue: blok.variant) ?? .solid,
            pattern: blok.pattern ?? Ascii.dividerStars,
            label: blok.label,
            color: Palette.named(blok.color)
        )
        .padding(.vertical, SpacingScale.points(blok.gap) ?? 0)
        .blokSpacing(blok.spacing)
    }
}

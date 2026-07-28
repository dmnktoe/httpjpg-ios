import DesignSystem
import SwiftUI

/// Renders the `section` blok.
public struct SbSectionView: View {
    private let blok: SectionBlok

    public init(blok: SectionBlok) {
        self.blok = blok
    }

    public var body: some View {
        BlokListView(blok.content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.named(blok.backgroundColor) ?? .clear)
            .blokSpacing(blok.spacing)
    }
}

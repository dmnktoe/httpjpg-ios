import DesignSystem
import SwiftUI

public struct SbSectionView: View {
    private let blok: SectionBlok

    public init(blok: SectionBlok) {
        self.blok = blok
    }

    public var body: some View {
        BlokListView(blok.content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                (Palette.named(blok.backgroundColor) ?? .clear)
                    .padding(.horizontal, -PageLayout.gutter)
            }
            .blokSpacing(blok.spacing, appliesHorizontal: false)
    }
}

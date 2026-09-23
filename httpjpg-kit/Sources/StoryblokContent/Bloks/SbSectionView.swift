import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

public struct SbSectionView: View {
    private let blok: SectionBlok

    public init(blok: SectionBlok) {
        self.blok = blok
    }

    public var body: some View {
        Group {
            if blok.usesContainer {
                BlokListView(blok.content)
                    .blokContainerFrame(
                        size: blok.containerSize,
                        centered: blok.containerAlign != "left"
                    )
            } else {
                BlokListView(blok.content)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            (Palette.named(blok.backgroundColor) ?? .clear)
                .padding(.horizontal, -PageLayout.gutter)
        }
        .blokSpacing(blok.spacing, appliesHorizontal: false)
    }
}

import StoryblokCore
import SwiftUI
import Tokens

public struct SbContainerView: View {
    private let blok: ContainerBlok

    public init(blok: ContainerBlok) {
        self.blok = blok
    }

    public var body: some View {
        BlokListView(blok.body)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.named(blok.backgroundColor) ?? .clear)
            .blokSpacing(blok.spacing, appliesHorizontal: false)
    }
}

import DesignSystem
import StoryblokCore
import SwiftUI

public struct SbGridItemView: View {
    private let blok: GridItemBlok

    public init(blok: GridItemBlok) {
        self.blok = blok
    }

    public var body: some View {
        BlokListView(blok.content, spacing: Spacing.s4)
    }
}

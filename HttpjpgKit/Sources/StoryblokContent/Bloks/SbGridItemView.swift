import DesignSystem
import SwiftUI

/// Renders the `grid_item` blok. Span settings are desktop-grid concerns and
/// collapse away on a phone, so only the nested content survives.
public struct SbGridItemView: View {
    private let blok: GridItemBlok

    public init(blok: GridItemBlok) {
        self.blok = blok
    }

    public var body: some View {
        BlokListView(blok.content, spacing: Spacing.s4)
    }
}

import DesignSystem
import SwiftUI

/// Renders the `grid` blok.
///
/// The CMS column counts describe desktop layouts. A phone is always below the
/// web's `md` breakpoint, where the grid collapses to a single column — so the
/// base `columns` value is honoured and the `…Md` / `…Lg` variants are ignored
/// rather than squeezed onto a 390pt screen.
public struct SbGridView: View {
    private let blok: GridBlok

    public init(blok: GridBlok) {
        self.blok = blok
    }

    public var body: some View {
        if blok.columns <= 1 {
            VStack(alignment: .leading, spacing: blok.gap) {
                ForEach(blok.items) { item in
                    item
                }
            }
            .blokSpacing(blok.spacing)
        } else {
            LazyVGrid(columns: columns, alignment: .leading, spacing: blok.gap) {
                ForEach(blok.items) { item in
                    item
                }
            }
            .blokSpacing(blok.spacing)
        }
    }

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: blok.gap, alignment: .topLeading),
            count: max(blok.columns, 1)
        )
    }
}

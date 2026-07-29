import DesignSystem
import SwiftUI

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

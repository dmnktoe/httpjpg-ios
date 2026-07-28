import DesignSystem
import SwiftUI

/// Renders the `section` blok.
///
/// The background runs full-bleed while the content keeps the page gutter,
/// which is what `<section>` does on the web: the coloured band reaches both
/// edges of the viewport and only the text inside it is inset. The screens pad
/// the whole body list horizontally, so the fill is pushed back out by exactly
/// that much — on the *background* view, which changes what gets painted
/// without changing what gets laid out.
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

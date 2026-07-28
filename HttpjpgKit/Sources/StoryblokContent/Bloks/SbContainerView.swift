import DesignSystem
import SwiftUI

/// Renders the `container` blok.
///
/// The CMS `width` field caps a desktop column; on a phone the container is
/// always the full width, so only the background and spacing carry over.
public struct SbContainerView: View {
    private let blok: ContainerBlok

    public init(blok: ContainerBlok) {
        self.blok = blok
    }

    public var body: some View {
        BlokListView(blok.body)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.named(blok.backgroundColor) ?? .clear)
            .blokSpacing(blok.spacing)
    }
}

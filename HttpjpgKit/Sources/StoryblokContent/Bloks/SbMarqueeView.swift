import DesignSystem
import SwiftUI

/// Renders the `marquee` blok.
public struct SbMarqueeView: View {
    private let blok: MarqueeBlok

    public init(blok: MarqueeBlok) {
        self.blok = blok
    }

    public var body: some View {
        Marquee(blok.text, rate: blok.rate)
            .blokSpacing(blok.spacing)
    }
}

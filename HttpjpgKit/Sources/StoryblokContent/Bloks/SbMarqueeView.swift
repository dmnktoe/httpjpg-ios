import DesignSystem
import SwiftUI

/// Renders the `marquee` blok.
public struct SbMarqueeView: View {
    private let blok: MarqueeBlok

    public init(blok: MarqueeBlok) {
        self.blok = blok
    }

    public var body: some View {
        if !blok.text.isEmpty {
            Marquee(
                // The web joins its repeats with a space; without one the last
                // `+++` of a copy runs straight into the first of the next.
                blok.text + " ",
                speed: .secondsPerCopy(blok.secondsPerCopy),
                direction: blok.isReversed ? .right : .left,
                repeatCount: blok.repeatCount
            )
            .blokSpacing(blok.spacing, appliesHorizontal: false)
        }
    }
}

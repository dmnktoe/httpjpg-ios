import DesignSystem
import SwiftUI

public struct SbMarqueeView: View {
    private let blok: MarqueeBlok

    public init(blok: MarqueeBlok) {
        self.blok = blok
    }

    public var body: some View {
        if !blok.text.isEmpty {
            Marquee(

                blok.text + " ",
                speed: .secondsPerCopy(blok.secondsPerCopy),
                direction: blok.isReversed ? .right : .left,
                repeatCount: blok.repeatCount
            )
            .blokSpacing(blok.spacing, appliesHorizontal: false)
        }
    }
}

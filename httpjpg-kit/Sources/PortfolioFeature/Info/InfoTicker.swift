import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

struct InfoTicker: View {
    let config: SiteConfig

    var body: some View {
        VStack(spacing: Spacing.s2) {
            BrutalDivider(variant: .dotted)
            Marquee(
                text,
                font: Typography.uiMono(Typography.Size.xs),
                speed: .rate(18)
            )
            .opacity(Opacities.muted)
            BrutalDivider(variant: .dotted)
        }
    }

    private var text: String {
        let parts = [config.displayName, config.authorName, config.seoDescription]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return "\(Ascii.askGlyph) " + parts.joined(separator: " ⋆ ") + " "
    }
}

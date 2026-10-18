import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

struct InfoHeader: View {
    let config: SiteConfig

    let pageCount: Int?

    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            HStack(alignment: .top, spacing: Spacing.s1) {
                ScrambleText("info", isActive: isActive) { text in
                    Headline(text, level: .two)
                }
                .fixedSize(horizontal: true, vertical: false)

                if let pageCount {
                    MonoText(
                        "(\(GlyphDigits.format(pageCount)))",
                        size: Typography.Size.xs,
                        opacity: Opacities.subtle
                    )
                    .padding(.top, Spacing.s1)
                    .accessibilityLabel(pageCount == 1 ? "1 page" : "\(pageCount) pages")
                    .transition(.opacity)
                }

                Spacer(minLength: 0)
            }
            .animation(Motion.stateChange, value: pageCount)

            ticker
        }
    }

    private var ticker: some View {
        VStack(spacing: Spacing.s2) {
            BrutalDivider(variant: .dotted)
            Marquee(
                tickerText,
                font: Typography.uiMono(Typography.Size.xs),
                speed: .rate(18)
            )
            .opacity(Opacities.muted)
            BrutalDivider(variant: .dotted)
        }
    }

    private var tickerText: String {
        let parts = [config.displayName, config.authorName, config.seoDescription]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return "\(Ascii.askGlyph) " + parts.joined(separator: " ⋆ ") + " "
    }
}

import DesignSystem
import StoryblokContent
import SwiftUI

/// Copyright, author, typeface credit, and the site's sign-off furniture.
struct InfoColophon: View {
    let config: SiteConfig
    let siteName: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            InfoSectionLabel("colophon")

            if let copyright = config.footer?.copyrightText {
                BodyText(copyright, size: .sm, emphasis: .muted)
            }
            if let author = config.authorName {
                MonoText(author, size: Typography.Size.sm, opacity: Opacities.muted)
            }

            // Names the face that actually resolved. Seeing the system
            // fallback here means the bundled font failed to register.
            MonoText(
                "set in \(Typography.Family.headline)",
                size: Typography.Size.xs,
                opacity: Opacities.subtle
            )

            Marquee(Ascii.tape + "  " + siteName + "  ")
                .padding(.top, Spacing.s2)

            AsciiArt(Ascii.ghost, label: "Ghost", size: Typography.Size.sm, opacity: Opacities.dimmed)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, Spacing.s6)
        }
    }
}

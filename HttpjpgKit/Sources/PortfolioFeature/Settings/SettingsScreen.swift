import DesignSystem
import StoryblokContent
import SwiftUI

/// Appearance switch and colophon.
///
/// The web flips themes per story from the CMS `isDark` field; the app keeps
/// that and adds a reader-level preference on top, which stories can still
/// override for their own screen.
struct SettingsScreen: View {
    @Binding var appearance: AppearancePreference
    @Binding var isGlassEnabled: Bool

    @Environment(AppModel.self) private var app
    @Environment(\.pageTheme) private var theme
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s8) {
                appearanceSection
                glassSection
                if !app.config.headerMenu.isEmpty {
                    linksSection
                }
                colophon
            }
            .padding(.horizontal, PageLayout.gutter)
            .padding(.vertical, Spacing.s6)
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            SectionLabel("appearance")
            SegmentedRow(
                options: AppearancePreference.allCases,
                selection: appearance,
                label: \.label,
                onSelect: { appearance = $0 }
            )
        }
    }

    /// Liquid Glass is the one thing in the app that argues with the design
    /// language, so it is a switch rather than a decision made for the reader.
    private var glassSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            SectionLabel("chrome")
            Toggle(isOn: $isGlassEnabled) {
                VStack(alignment: .leading, spacing: Spacing.s1) {
                    MonoText("liquid glass", size: Typography.Size.sm)
                    BodyText(glassFootnote, size: .sm, emphasis: .dimmed)
                }
            }
            .tint(theme.foreground)
        }
    }

    private var glassFootnote: String {
        isLiquidGlassAvailable
            ? "Masthead and tab bar float as glass; content stays flat."
            : "This device predates Liquid Glass — the chrome falls back to a blur."
    }

    private var linksSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            SectionLabel("elsewhere")
            ForEach(app.config.headerMenu) { link in
                if let url = link.link?.resolvedURL(siteOrigin: app.configuration.siteOrigin) {
                    Button {
                        openURL(url)
                    } label: {
                        HStack {
                            MonoText(link.label.lowercased(), size: Typography.Size.sm)
                            Spacer(minLength: 0)
                            MonoText("↗", size: Typography.Size.sm, opacity: Opacities.subtle)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var colophon: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            SectionLabel("colophon")
            if let copyright = app.config.footer?.copyrightText {
                BodyText(copyright, size: .sm, emphasis: .muted)
            }
            if let author = app.config.authorName {
                MonoText(author, size: Typography.Size.sm, opacity: Opacities.muted)
            }
            // Names the face that actually resolved. Anton is SIL OFL 1.1, and
            // seeing "HelveticaNeue-CondensedBlack" here means the bundled font
            // failed to register.
            MonoText(
                "set in \(Typography.Family.headline)",
                size: Typography.Size.xs,
                opacity: Opacities.subtle
            )
            Marquee(Ascii.tape + "  " + app.siteName + "  ")
                .padding(.top, Spacing.s2)
            AsciiArt(Ascii.ghost, label: "Ghost", size: Typography.Size.sm, opacity: Opacities.dimmed)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, Spacing.s6)
        }
    }
}

private struct SectionLabel: View {
    private let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        MonoText(text, size: Typography.Size.xs, tracking: Typography.Size.xs * 0.2, opacity: Opacities.subtle)
            .textCase(.uppercase)
            .accessibilityAddTraits(.isHeader)
    }
}

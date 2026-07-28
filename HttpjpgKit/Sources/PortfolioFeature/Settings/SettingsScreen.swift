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

    @Environment(AppModel.self) private var app
    @Environment(\.pageTheme) private var theme
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s8) {
                appearanceSection
                if !app.config.headerMenu.isEmpty {
                    linksSection
                }
                colophon
            }
            .padding(.horizontal, Layout.gutter)
            .padding(.vertical, Spacing.s6)
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            SectionLabel("appearance")
            HStack(spacing: 0) {
                ForEach(AppearancePreference.allCases) { option in
                    Button {
                        appearance = option
                    } label: {
                        Text(option.label)
                            .font(Typography.mono(
                                Typography.Size.sm,
                                weight: option == appearance ? .bold : .regular
                            ))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.s3)
                            .background(option == appearance ? theme.foreground : .clear)
                            .foregroundStyle(option == appearance ? theme.background : theme.foreground)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(option == appearance ? [.isSelected, .isButton] : .isButton)
                }
            }
            .overlay(Rectangle().stroke(theme.foreground, lineWidth: 1))
        }
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

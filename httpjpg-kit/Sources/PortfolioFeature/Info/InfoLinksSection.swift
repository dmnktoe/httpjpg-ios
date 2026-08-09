import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

struct InfoLinksSection: View {
    let links: [MenuLink]

    @Environment(\.openURL) private var openURL
    @Environment(\.storyblokConfiguration) private var configuration
    @Environment(\.pageTheme) private var theme

    var body: some View {
        if !external.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                InfoSectionLabel("elsewhere")
                    .padding(.bottom, Spacing.s3)

                ForEach(external, id: \.link.id) { entry in
                    Button {
                        openURL(entry.url)
                    } label: {
                        HStack(spacing: Spacing.s2) {
                            Favicon(for: entry.url)
                            MonoText(entry.link.label.lowercased(), size: Typography.Size.sm)
                            Spacer(minLength: 0)
                            MonoText("↗", size: Typography.Size.sm)
                                .foregroundStyle(theme.link)
                        }
                        .padding(.vertical, Spacing.s3)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    BrutalDivider(variant: .dotted)
                }
            }
        }
    }

    private var external: [(link: MenuLink, url: URL)] {
        links.compactMap { link in
            guard let url = link.link?.resolvedURL(siteOrigin: configuration.siteOrigin),
                  let scheme = url.scheme,
                  scheme == "http" || scheme == "https" || scheme == "mailto",
                  url.host != configuration.siteOrigin.host
            else { return nil }
            return (link, url)
        }
    }
}

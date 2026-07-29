import DesignSystem
import StoryblokContent
import SwiftUI

struct InfoFooter: View {
    let config: SiteConfig
    let widgets: FooterWidgetsModel

    @Environment(\.openURL) private var openURL
    @Environment(\.storyblokConfiguration) private var configuration

    var body: some View {
        VStack(spacing: 0) {
            if !links.isEmpty {
                linkRow
            }

            if let copyright = config.footer?.copyrightText {
                Text(copyright)
                    .font(Typography.mono(Typography.Size.sm))
                    .multilineTextAlignment(.center)
                    .padding(.top, Spacing.s2)
            }

            MonoText(Ascii.dividerStars, size: Typography.Size.sm, opacity: Opacities.subtle)
                .padding(.vertical, Spacing.s6)

            FooterWidgets(model: widgets)

            AsciiArt(
                Ascii.dividerWave,
                label: "signoff",
                size: Typography.Size.xs,
                opacity: Opacities.dimmed
            )
            .padding(.vertical, Spacing.s5)

            MonoText(version, size: Typography.Size.xs, tracking: Typography.Size.xs * 0.05)
                .opacity(0.4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.s12)
        .background(alignment: .center) { backgroundImage }
    }

    @ViewBuilder
    private var backgroundImage: some View {
        if let url = config.footer?.backgroundImage?.filename.flatMap(URL.init(string:)) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.clear
            }
            .clipped()
            .accessibilityHidden(true)
        }
    }

    private var linkRow: some View {
        FlowLayout(spacing: Spacing.s2) {
            ForEach(Array(links.enumerated()), id: \.offset) { entry in
                if entry.offset > 0 {
                    Text("·")
                        .font(Typography.mono(Typography.Size.sm))
                        .opacity(Opacities.subtle)
                }
                Button {
                    openURL(entry.element.url)
                } label: {
                    Text(entry.element.label)
                        .font(Typography.mono(Typography.Size.sm))
                        .underline()
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, PageLayout.gutter)
    }

    private var links: [(label: String, url: URL)] {
        (config.footer?.links ?? []).compactMap { link in
            guard !link.label.isEmpty,
                  let url = link.link?.resolvedURL(siteOrigin: configuration.siteOrigin)
            else { return nil }
            return (link.label, url)
        }
    }

    private var version: String {
        let bundle = Bundle.main
        let short = bundle.infoDictionary?["CFBundleShortVersionString"] as? String
        let build = bundle.infoDictionary?["CFBundleVersion"] as? String
        guard let short else { return "v-dev" }
        return build.map { "v\(short) (\($0))" } ?? "v\(short)"
    }
}

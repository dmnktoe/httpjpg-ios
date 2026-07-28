import DesignSystem
import StoryblokContent
import SwiftUI

/// The site footer, natively.
///
/// A straight port of `@httpjpg/ui`'s `<Footer>`, in the same order: the CMS
/// footer links in one centred wrapping row separated by `·`, the copyright
/// line, the star rule, the live widgets, the sign-off wave, and the version.
///
/// One thing the web does is deliberately dropped: Cookie Settings and Cookie
/// Policy. The app sets no cookies and runs no analytics, so offering to
/// configure them would be a lie.
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

    /// The CMS's `background_image`, behind the text and bleeding to both
    /// edges — `background-size: cover; background-position: center`, natively.
    ///
    /// `AsyncImage` rather than `RemoteImage`: this one is decoration, it has no
    /// size to reserve and nothing to fall back to. A footer that fails to load
    /// its wallpaper is a footer, not an error.
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

    /// A wrapping row, because "Legal Notice · Privacy Policy · pr0d for
    /// listening purposes only" does not fit a phone on one line and the web
    /// wraps it too.
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

    /// `footer_links` from the config story, resolved against the site origin so
    /// an internal `/legal-notice` opens the real page rather than nothing.
    private var links: [(label: String, url: URL)] {
        (config.footer?.links ?? []).compactMap { link in
            guard !link.label.isEmpty,
                  let url = link.link?.resolvedURL(siteOrigin: configuration.siteOrigin)
            else { return nil }
            return (link.label, url)
        }
    }

    /// The app's own build, not the website's release tag — on the web the
    /// footer names the thing you are looking at, and here that is the app.
    private var version: String {
        let bundle = Bundle.main
        let short = bundle.infoDictionary?["CFBundleShortVersionString"] as? String
        let build = bundle.infoDictionary?["CFBundleVersion"] as? String
        guard let short else { return "v-dev" }
        return build.map { "v\(short) (\($0))" } ?? "v\(short)"
    }
}

import DesignSystem
import Observation
import StoryblokContent
import SwiftUI
import WidgetFeature

/// App-wide state: the content client, the CMS config, and which tab is up.
///
/// The counterpart of what `app/layout.tsx` assembles on the web — navigation
/// and site config fetched once, then handed to every screen below.
@MainActor
@Observable
public final class AppModel {
    /// Two tabs. There is no third for settings — the app has no settings.
    public enum Tab: String, CaseIterable, Identifiable, Sendable {
        case work
        case info

        public var id: String { rawValue }

        /// Tab labels are set in the site's own voice — which is to say, in
        /// whatever Unicode the site feels like that day.
        public var label: String {
            switch self {
            case .work: return "🎀 ୧ꔛꗃ˖ աօʀӄ"
            case .info: return "👊🐯  ᶤⓝƒ𝓸  💀☟"
            }
        }

        /// What VoiceOver says, since the label above does not survive being
        /// read aloud.
        public var accessibilityLabel: String {
            switch self {
            case .work: return "Work"
            case .info: return "Info"
            }
        }
    }

    public let client: ContentClient
    public var selectedTab: Tab = .work
    /// The work tab's navigation stack, hoisted out of the screen so a widget
    /// tap can push onto it before the screen has even appeared.
    public var workPath: [WorkRoute] = []
    /// The external preview link of the story currently on screen, if it has
    /// one. The detail screen sets it, the tab bar shows it as an extra pill.
    public var previewURL: URL?
    public private(set) var config: SiteConfig = .fallback
    /// Public because the footer's widget flags are meaningless until the real
    /// config lands — reading them off `.fallback` would report every widget as
    /// disabled and never retry.
    public private(set) var hasLoadedConfig = false

    public init(configuration: StoryblokConfiguration) {
        self.client = ContentClient(configuration: configuration)
    }

    public var configuration: StoryblokConfiguration { client.configuration }

    /// The site's own name, from `config.seo_title`, falling back to the
    /// `appName` the web keeps in `lib/config.ts`.
    public var siteName: String {
        config.seoTitle ?? "㋡httpjpg.com"
    }

    public func loadConfig() async {
        guard !hasLoadedConfig else { return }
        config = await client.siteConfig()
        hasLoadedConfig = true
    }

    /// Handles a `httpjpg://work/<slug>` URL from the home-screen widget.
    ///
    /// The title is the slug until the story loads — the widget knows the
    /// title, but passing it through the URL would make the link brittle for
    /// no benefit, since the detail screen replaces it a moment later anyway.
    public func open(_ url: URL) {
        guard let slug = WidgetDeepLink.workSlug(from: url) else { return }
        selectedTab = .work
        workPath = [WorkRoute(slug: slug, title: slug)]
    }

    /// Selects a tab, or — when it is already selected — pops it back to its
    /// root. Tapping the current tab to get home is how every iOS tab bar
    /// behaves, and it is the only way back that does not depend on the swipe.
    public func select(tab: Tab) {
        guard tab == selectedTab else {
            selectedTab = tab
            return
        }
        if tab == .work {
            workPath.removeAll()
        }
    }
}

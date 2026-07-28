import DesignSystem
import Observation
import StoryblokContent
import SwiftUI

/// App-wide state: the content client, the CMS config, and which tab is up.
///
/// The counterpart of what `app/layout.tsx` assembles on the web — navigation
/// and site config fetched once, then handed to every screen below.
@MainActor
@Observable
public final class AppModel {
    public enum Tab: String, CaseIterable, Identifiable, Sendable {
        case work
        case info
        case settings

        public var id: String { rawValue }

        /// Tab labels are set in the site's own voice, lowercase and mono.
        public var label: String {
            switch self {
            case .work: return "work"
            case .info: return "info"
            case .settings: return "settings"
            }
        }
    }

    public let client: ContentClient
    public var selectedTab: Tab = .work
    public private(set) var config: SiteConfig = .fallback

    private var hasLoadedConfig = false

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
}

/// How the app picks between the light and dark page themes.
public enum AppearancePreference: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .system: return "system"
        case .light: return "light"
        case .dark: return "dark"
        }
    }

    public func theme(systemScheme: ColorScheme) -> PageTheme {
        switch self {
        case .system: return systemScheme == .dark ? .dark : .light
        case .light: return .light
        case .dark: return .dark
        }
    }
}

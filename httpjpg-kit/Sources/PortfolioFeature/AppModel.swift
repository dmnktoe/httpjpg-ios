import DesignSystem
import Observation
import StoryblokContent
import SwiftUI
import WidgetFeature

@MainActor
@Observable
public final class AppModel {
    public enum Tab: String, CaseIterable, Identifiable, Sendable {
        case work
        case info

        public var id: String { rawValue }

        public var label: String {
            switch self {
            case .work: return "🎀 ୧ꔛꗃ˖ աօʀӄ"
            case .info: return "👊🐯  ᶤⓝƒ𝓸  💀☟"
            }
        }

        public var accessibilityLabel: String {
            switch self {
            case .work: return "Work"
            case .info: return "Info"
            }
        }
    }

    public let client: ContentClient
    public var selectedTab: Tab = .work

    public var workPath: [WorkRoute] = []

    public var infoPath: [PageRoute] = []

    public var previewURL: URL?
    public private(set) var config: SiteConfig = .fallback

    public private(set) var hasLoadedConfig = false

    // The tab roots are rebuilt from scratch on every switch, so what they loaded
    // lives here instead of in their own state — otherwise each visit starts over
    // from an empty screen.
    let workIndex: WorkIndexModel
    let info: InfoModel
    private(set) var footerWidgets: FooterWidgetsModel?

    public init(configuration: StoryblokConfiguration) {
        let client = ContentClient(configuration: configuration)
        self.client = client
        self.workIndex = WorkIndexModel(client: client)
        self.info = InfoModel(client: client)
    }

    public var configuration: StoryblokConfiguration { client.configuration }

    public var siteName: String {
        config.seoTitle ?? "㋡httpjpg.com"
    }

    public func loadConfig() async {
        guard !hasLoadedConfig else { return }
        config = await client.siteConfig()
        hasLoadedConfig = true
    }

    /// Kept off the launch path: nothing here is worth fetching until the info tab is open.
    func loadFooterWidgets() async {
        guard hasLoadedConfig, footerWidgets == nil else { return }
        let widgets = FooterWidgetsModel(origin: configuration.siteOrigin, flags: config.widgets)
        footerWidgets = widgets
        await widgets.load()
    }

    public func open(_ url: URL) {
        guard let slug = WidgetDeepLink.workSlug(from: url) else { return }
        selectedTab = .work
        workPath = [WorkRoute(slug: slug, title: slug)]
    }

    public func select(tab: Tab) {
        guard tab == selectedTab else {
            selectedTab = tab
            return
        }
        switch tab {
        case .work: workPath.removeAll()
        case .info: infoPath.removeAll()
        }
    }
}

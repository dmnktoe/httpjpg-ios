import DesignSystem
import Observation
import StoryblokCore
import SwiftUI
import WidgetFeature
import WidgetKit

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
            case .info: return "👊🐯  ᶤⓝƒ𝓸"
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
    public var selectedTab: Tab = .work {
        didSet { visitedTabs.insert(selectedTab) }
    }

    /// Tabs that have been shown at least once. RootView keeps their roots
    /// mounted so switching back doesn't rebuild the stack (and flicker).
    private(set) var visitedTabs: Set<Tab> = [.work]

    public var workPath: [WorkRoute] = []

    public var infoPath: [PageRoute] = []

    public var isSidebarOpen = false {
        didSet {
            guard isSidebarOpen, !oldValue else { return }
            Task { Telemetry.signal("sidebar.opened") }
        }
    }
    public private(set) var config: SiteConfig = .fallback

    public private(set) var hasLoadedConfig = false

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

    func loadFooterWidgets() async {
        guard hasLoadedConfig, footerWidgets == nil else { return }
        let widgets = FooterWidgetsModel(origin: configuration.siteOrigin, flags: config.widgets)
        footerWidgets = widgets
        await widgets.load()
    }

    func resetCacheAndReload() async {
        client.clearCache()
        ImageCache.clear()
        await VideoCache.shared.clear()

        config = await client.siteConfig(refresh: true)
        hasLoadedConfig = true

        let widgets = FooterWidgetsModel(origin: configuration.siteOrigin, flags: config.widgets)
        footerWidgets = widgets

        await workIndex.load(force: true)
        await info.load(force: true)
        await widgets.load()

        // The widget extension is a separate process with its own data container
        // and its own ContentClient, so nothing cleared above reaches it. Asking
        // WidgetKit to reload is the only way in: the providers build a fresh
        // client per timeline, so their cache dies with it.
        WidgetCenter.shared.reloadAllTimelines()
    }

    public func open(_ url: URL) {
        switch WidgetDeepLink.destination(from: url) {
        case .work(let slug):
            show(WorkRoute(slug: slug, title: slug))
        case .workIndex:
            select(tab: .work)
            workPath.removeAll()
            isSidebarOpen = false
        case .page(let slug):
            // A link carries the slug and nothing else, so it doubles as the title —
            // same stand-in the work routes use.
            show(PageRoute(slug: slug, title: slug))
        case .info:
            select(tab: .info)
            infoPath.removeAll()
            isSidebarOpen = false
        case nil:
            return
        }
    }

    func perform(_ action: QuickAction) {
        guard let route = action.route else { return }
        Telemetry.signal("quickaction.opened", parameters: ["kind": action.kind.rawValue])
        show(route)
    }

    private func show(_ route: WorkRoute) {
        selectedTab = .work
        workPath = [route]
        isSidebarOpen = false
    }

    private func show(_ route: PageRoute) {
        selectedTab = .info
        infoPath = [route]
        isSidebarOpen = false
    }

    func open(work item: WorkItem) {
        show(WorkRoute(item: item))
    }

    func toggleSidebar() {
        isSidebarOpen.toggle()
    }

    var isAtNavigationRoot: Bool {
        switch selectedTab {
        case .work: return workPath.isEmpty
        case .info: return infoPath.isEmpty
        }
    }

    /// Bumped when re-selecting a tab that is already at its root; the tab's
    /// scroll view scrolls back to the top in response.
    private(set) var scrollToTopTicks: [Tab: Int] = [:]

    func scrollToTopTick(for tab: Tab) -> Int {
        scrollToTopTicks[tab] ?? 0
    }

    public func select(tab: Tab) {
        guard tab == selectedTab else {
            selectedTab = tab
            return
        }
        switch tab {
        case .work:
            if workPath.isEmpty {
                scrollToTopTicks[.work, default: 0] += 1
            } else {
                workPath.removeAll()
            }
        case .info:
            if infoPath.isEmpty {
                scrollToTopTicks[.info, default: 0] += 1
            } else {
                infoPath.removeAll()
            }
        }
    }
}

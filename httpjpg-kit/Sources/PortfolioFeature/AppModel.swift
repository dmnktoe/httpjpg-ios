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

    private(set) var visitedTabs: Set<Tab> = [.work]

    public var workPath: [WorkRoute] = []

    private(set) var workRouteToken = 0

    public var infoPath: [PageRoute] = []

    public var isSidebarOpen = false {
        didSet {
            guard isSidebarOpen, !oldValue else { return }
            Task { Telemetry.signal("sidebar.opened") }
        }
    }
    public private(set) var config: SiteConfig = .fallback

    public private(set) var hasLoadedConfig = false

    private(set) var pendingPlayback: AudioTrack?

    let workIndex: WorkIndexModel
    let info: InfoModel
    private(set) var footerWidgets: FooterWidgetsModel?
    /// Nil until config says Ask is on — mirrors the web mount gate.
    private(set) var askSearch: AskSearchModel?
    /// Held when a deep link / intent opens search before config has loaded.
    private var pendingSearch: PendingSearch?

    private struct PendingSearch {
        let query: String?
    }

    public init(configuration: StoryblokConfiguration) {
        let client = ContentClient(configuration: configuration)
        self.client = client
        self.workIndex = WorkIndexModel(client: client)
        self.info = InfoModel(client: client)
    }

    public var configuration: StoryblokConfiguration { client.configuration }

    public var siteName: String {
        config.displayName
    }

    public var defaultPageTitle: String {
        config.defaultPageTitle
    }

    public func loadConfig() async {
        guard !hasLoadedConfig else { return }
        config = await client.siteConfig()
        hasLoadedConfig = true
        syncAskSearch()
        flushPendingSearch()
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
        syncAskSearch()
        flushPendingSearch()

        let widgets = FooterWidgetsModel(origin: configuration.siteOrigin, flags: config.widgets)
        footerWidgets = widgets

        await workIndex.load(force: true)
        await info.load(force: true)
        await widgets.load()

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
            show(PageRoute(slug: slug, title: slug))
        case .info:
            select(tab: .info)
            infoPath.removeAll()
            isSidebarOpen = false
        case .search(let query):
            openAskSearch(prefill: query)
        case .play(let track):
            pendingPlayback = track
            show(PageRoute(slug: StorySlug.feed, title: StorySlug.feed))
        case nil:
            return
        }
    }

    func takePendingPlayback() -> AudioTrack? {
        defer { pendingPlayback = nil }
        return pendingPlayback
    }

    func perform(_ action: QuickAction) {
        Telemetry.signal("quickaction.opened", parameters: ["kind": action.kind.rawValue])
        switch action {
        case .search(let query):
            openAskSearch(prefill: query)
        case .work, .shuffle:
            guard let route = action.route else { return }
            show(route)
        }
    }

    func openAskSearch(prefill: String? = nil) {
        guard hasLoadedConfig else {
            pendingSearch = PendingSearch(query: prefill)
            return
        }
        syncAskSearch()
        guard let askSearch else { return }
        isSidebarOpen = false
        askSearch.open(prefill: prefill)
    }

    func navigate(_ destination: SearchDestination) {
        switch destination {
        case .work(let slug, let title):
            show(WorkRoute(slug: slug, title: title))
        case .page(let slug, let title):
            show(PageRoute(slug: slug, title: title))
        case .workIndex:
            select(tab: .work)
            workPath.removeAll()
            isSidebarOpen = false
        case .external:
            break
        }
    }

    private func syncAskSearch() {
        guard config.widgets.isAskEnabled else {
            askSearch?.close()
            askSearch = nil
            return
        }
        if askSearch == nil {
            askSearch = AskSearchModel(origin: configuration.siteOrigin)
        }
    }

    private func flushPendingSearch() {
        guard let pending = pendingSearch else { return }
        pendingSearch = nil
        openAskSearch(prefill: pending.query)
    }

    private func show(_ route: WorkRoute) {
        selectedTab = .work
        workPath = [route]
        workRouteToken &+= 1
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

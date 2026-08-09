import DesignSystem
import Observation
import StoryblokCore
import SwiftUI
import Tokens

struct InfoScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(\.bottomBarClearance) private var bottomBarClearance

    var body: some View {
        @Bindable var app = app
        return NavigationStack(path: $app.infoPath) {
            ScrollToTopReader(tick: app.scrollToTopTick(for: .info)) {
                infoList
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sidebarMenuToolbar()
            .navigationDestination(for: PageRoute.self) { route in
                PageScreen(slug: route.slug, title: route.title, isDarkHint: route.isDark)
            }
        }
        .task { await app.info.load() }
        .task(id: app.hasLoadedConfig) { await app.loadFooterWidgets() }
    }

    private var infoList: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: Spacing.s8) {
                    // In the content like the work masthead, not a UIKit
                    // large title: that one re-lays out against the moving
                    // safe area while the sidebar pushes the stack aside
                    // and visibly jumps to the edge.
                    Headline("info", level: .two)

                    pages
                    InfoLinksSection(links: app.config.headerMenu)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, PageLayout.gutter)
                .padding(.top, Spacing.s2)

                Group {
                    if let widgets = app.footerWidgets {
                        InfoFooter(config: app.config, widgets: widgets)
                            .transition(.opacity)
                    }
                }
                .animation(Motion.stateChange, value: app.footerWidgets == nil)

                InfoResetCacheButton { await app.resetCacheAndReload() }
                    .padding(.top, Spacing.s4)
                    .padding(.bottom, Spacing.s10)
            }
            .padding(.bottom, bottomBarClearance)
            .scrollToTopAnchor()
        }
        .softScrollEdges()
        .refreshable {
            await app.info.load(force: true)
            await app.footerWidgets?.load()
        }
    }

    @ViewBuilder
    private var pages: some View {
        VStack(alignment: .leading, spacing: 0) {
            InfoSectionLabel("pages")
                .padding(.bottom, Spacing.s3)

            FadeSwap(key: app.info.isLoaded) {
                VStack(alignment: .leading, spacing: 0) {
                    switch app.info.state {
                    case .loaded(let summaries) where !summaries.isEmpty:
                        ForEach(summaries) { page in
                            NavigationLink(value: PageRoute(page: page)) {
                                InfoPageRow(page: page)
                            }
                            .buttonStyle(.plain)
                            BrutalDivider(variant: .dotted)
                        }
                    case .loaded:
                        MonoText("∅ nothing published yet", size: Typography.Size.sm, opacity: Opacities.subtle)
                            .padding(.vertical, Spacing.s3)
                    case .failed(let message):
                        BodyText(message, size: .sm, emphasis: .muted)
                    case .loading:
                        InfoPagesSkeleton()
                    }
                }
            }
        }
    }
}

public struct PageRoute: Hashable, Sendable {
    public let slug: String
    public let title: String

    /// Dark-art-direction hint from the index payload, so the page renders
    /// its scene correctly before its own request lands.
    public let isDark: Bool

    init(page: PageSummary) {
        slug = page.slug
        title = page.title
        isDark = page.isDark
    }

    public init(slug: String, title: String, isDark: Bool = false) {
        self.slug = slug
        self.title = title
        self.isDark = isDark
    }
}

@MainActor
@Observable
final class InfoModel {
    enum LoadState {
        case loading
        case loaded([PageSummary])
        case failed(String)
    }

    private let client: ContentClient

    private(set) var state: LoadState = .loading
    private var isLoading = false

    init(client: ContentClient) {
        self.client = client
    }

    var isLoaded: Bool {
        if case .loaded = state { return true }
        return false
    }

    func load(force: Bool = false) async {
        guard !isLoading, force || !isLoaded else { return }
        isLoading = true
        defer { isLoading = false }

        let hadContent = isLoaded
        if !hadContent {
            state = .loading
        }

        do {
            state = .loaded(try await client.pageIndex(refresh: force))
        } catch {
            guard !Task.isCancelled, !hadContent else { return }
            state = .failed(error.localizedDescription)
        }
    }
}

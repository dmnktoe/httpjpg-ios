import DesignSystem
import Observation
import StoryblokContent
import SwiftUI

struct InfoScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(\.bottomBarClearance) private var bottomBarClearance

    var body: some View {
        @Bindable var app = app
        return NavigationStack(path: $app.infoPath) {
            ScrollView {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: Spacing.s8) {
                        pages
                        InfoLinksSection(links: app.config.headerMenu)
                    }

                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, PageLayout.gutter)
                    .padding(.top, Spacing.s6)

                    if let widgets = app.footerWidgets {
                        InfoFooter(config: app.config, widgets: widgets)
                    }
                }
                .padding(.bottom, bottomBarClearance)
            }
            .refreshable {
                await app.info.load(force: true)
                await app.footerWidgets?.load()
            }
            .navigationTitle("info")
            .navigationBarTitleDisplayMode(.large)
            .sidebarMenuToolbar()
            .navigationDestination(for: PageRoute.self) { route in
                PageScreen(slug: route.slug, title: route.title)
            }
        }
        .task { await app.info.load() }
        .task(id: app.hasLoadedConfig) { await app.loadFooterWidgets() }
    }

    @ViewBuilder
    private var pages: some View {
        VStack(alignment: .leading, spacing: 0) {
            InfoSectionLabel("pages")
                .padding(.bottom, Spacing.s3)

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

public struct PageRoute: Hashable, Sendable {
    public let slug: String
    public let title: String

    init(page: PageSummary) {
        slug = page.slug
        title = page.title
    }

    public init(slug: String, title: String) {
        self.slug = slug
        self.title = title
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

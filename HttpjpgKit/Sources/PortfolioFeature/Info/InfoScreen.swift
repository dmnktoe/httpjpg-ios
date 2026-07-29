import DesignSystem
import Observation
import StoryblokContent
import SwiftUI

struct InfoScreen: View {
    @Environment(AppModel.self) private var app

    @State private var model: InfoModel?
    @State private var widgets: FooterWidgetsModel?

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

                    if let widgets {
                        InfoFooter(config: app.config, widgets: widgets)
                    }
                }
                .padding(.bottom, TabBarClearance.bottomPadding)
            }
            .refreshable {
                await model?.load()
                await widgets?.load()
            }
            .navigationTitle("info")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: PageRoute.self) { route in
                PageScreen(slug: route.slug, title: route.title)
            }
        }
        .task {
            if model == nil {
                model = InfoModel(client: app.client)
                await model?.load()
            }
        }

        .task(id: app.hasLoadedConfig) {
            guard app.hasLoadedConfig, widgets == nil else { return }
            let model = FooterWidgetsModel(
                origin: app.configuration.siteOrigin,
                flags: app.config.widgets
            )
            widgets = model
            await model.load()
        }
    }

    @ViewBuilder
    private var pages: some View {
        VStack(alignment: .leading, spacing: 0) {
            InfoSectionLabel("pages")
                .padding(.bottom, Spacing.s3)

            switch model?.state {
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
            case .none, .loading:
                MonoText("loading …", size: Typography.Size.sm, opacity: Opacities.subtle)
                    .padding(.vertical, Spacing.s3)
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

    init(client: ContentClient) {
        self.client = client
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await client.pageIndex())
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

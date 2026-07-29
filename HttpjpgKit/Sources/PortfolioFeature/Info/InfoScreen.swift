import DesignSystem
import Observation
import StoryblokContent
import SwiftUI

/// The info tab: everything on the site that isn't work, plus the links and
/// preferences that used to sit in a tab of their own.
///
/// It used to point at the `home` story, which was a mistake — on the web
/// `home` *is* the work index, so the tab either duplicated the first one or
/// rendered blank. There is no canonical "about" slug to point at instead, so
/// the pages are discovered: every story outside `work/`, listed, opened
/// through the same blok registry the web uses.
struct InfoScreen: View {
    @Environment(AppModel.self) private var app

    @State private var model: InfoModel?
    @State private var widgets: FooterWidgetsModel?

    var body: some View {
        // The path lives on `AppModel` so tapping the info pill can pop it.
        @Bindable var app = app
        return NavigationStack(path: $app.infoPath) {
            ScrollView {
                // The clearance lives on the *content*, not the scroll view —
                // padding the scroll view would end it above the tab pills and
                // leave the glass nothing to refract.
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: Spacing.s8) {
                        pages
                        InfoLinksSection(links: app.config.headerMenu)
                    }
                    // Pinned to the full width: with no rows to stretch it,
                    // the column hugged its short labels and the outer stack
                    // centred the lot.
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, PageLayout.gutter)
                    .padding(.top, Spacing.s6)

                    // Full-bleed: the footer is centred and has its own gutter,
                    // so it sits outside the column above rather than inside it.
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
        // Separate from the pages task: the widget flags only exist once the
        // config story lands, and starting before then would read them as off.
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
                // Loaded and empty is an answer, not a pending state — this
                // used to fall into the "loading …" arm and sit there forever.
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

/// A page destination. Carries the title so the pushed screen has something to
/// show in its navigation bar before the story arrives.
///
/// Public because `AppModel.infoPath` is — a public property cannot carry an
/// internal element type.
public struct PageRoute: Hashable, Sendable {
    public let slug: String
    public let title: String

    init(page: PageSummary) {
        slug = page.slug
        title = page.title
    }

    /// For universal links, where all that exists is the path.
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

import DesignSystem
import Observation
import StoryblokContent
import StoryblokCore
import SwiftUI
import Tokens

struct PageScreen: View {
    let slug: String
    let title: String
    var isDarkHint: Bool = false

    @Environment(AppModel.self) private var app
    @Environment(\.bottomBarClearance) private var bottomBarClearance

    @State private var model: PageModel?

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                LoadingState()
            }
        }
        .pageSurface(forcingDark: pageIsDark)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        // toolbarColorScheme doesn't reach the status bar when the bar is
        // transparent; forcing the scheme does. Tied to the selected tab and
        // the top of the path: the stack stays mounted across tab switches,
        // and coupling to the path flips the scene when a pop starts instead
        // of snapping after the pop animation finishes.
        .preferredColorScheme(forcesDark ? .dark : nil)
        .task {
            if model == nil {
                model = PageModel(client: app.client, slug: slug)
                await model?.load()
            }
        }
    }

    private var loadedPage: PageDocument? {
        guard let model, case .loaded(let page) = model.state else { return nil }
        return page
    }

    // The route's hint bridges the load; the loaded page is the truth.
    private var pageIsDark: Bool {
        loadedPage?.isDark ?? isDarkHint
    }

    private var forcesDark: Bool {
        pageIsDark && app.selectedTab == .info && app.infoPath.last?.slug == slug
    }

    @ViewBuilder
    private func content(_ model: PageModel) -> some View {
        switch model.state {
        case .loading:
            LoadingState(label: slug)
        case .failed(let error):
            AsciiState(
                art: error.isNotFound ? Ascii.notFound : Ascii.error,
                label: error.isNotFound ? "Not found" : "Something broke",
                message: error.errorDescription
            ) {
                Task { await model.load() }
            }
        case .loaded(let page):
            document(page)
        }
    }

    @ViewBuilder
    private func document(_ page: PageDocument) -> some View {
        if page.body.isEmpty {
            AsciiState(
                art: Ascii.ghost,
                label: "Nothing to render",
                message: "\"\(page.title)\" has no bloks this app knows how to draw yet."
            )
        } else {
            ScrollView {
                BlokListView(page.body, appliesPageGutter: true)
                    .padding(.top, Spacing.s6)
                    .padding(.bottom, bottomBarClearance)
            }
            .softScrollEdges()
        }
    }
}

@MainActor
@Observable
final class PageModel {
    enum LoadState {
        case loading
        case loaded(PageDocument)
        case failed(ContentError)
    }

    private let client: ContentClient
    let slug: String

    private(set) var state: LoadState = .loading

    init(client: ContentClient, slug: String) {
        self.client = client
        self.slug = slug
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await client.page(slug: slug))
        } catch let error as ContentError {
            state = .failed(error)
        } catch {
            state = .failed(.transport(error.localizedDescription))
        }
    }
}

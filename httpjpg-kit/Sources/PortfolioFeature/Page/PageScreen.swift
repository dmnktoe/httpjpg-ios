import DesignSystem
import Observation
import StoryblokContent
import SwiftUI

struct PageScreen: View {
    let slug: String
    let title: String

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
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if model == nil {
                model = PageModel(client: app.client, slug: slug)
                await model?.load()
            }
        }
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
        let theme = page.isDark ? PageTheme.dark : PageTheme.light
        if page.body.isEmpty {
            AsciiState(
                art: Ascii.ghost,
                label: "Nothing to render",
                message: "\"\(page.title)\" has no bloks this app knows how to draw yet."
            )
            .pageTheme(theme)
            .pageSurface(theme)
        } else {
            ScrollView {
                BlokListView(page.body, appliesPageGutter: true)
                    .padding(.top, Spacing.s6)
                    .padding(.bottom, bottomBarClearance)
            }
            .pageTheme(theme)
            .pageSurface(theme)
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

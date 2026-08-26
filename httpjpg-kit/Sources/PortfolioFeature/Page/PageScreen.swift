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

    @AppStorage("cvLocale") private var storedLocale = AppLocale.en.rawValue
    @State private var model: PageModel?

    private var showsLanguagePicker: Bool {
        LocalizedContent.showsLanguagePicker(for: slug)
    }

    private var locale: AppLocale {
        AppLocale(rawValue: storedLocale) ?? .en
    }

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                LoadingState()
            }
        }
        .pageSurface(forcingDark: pageIsDark)
        .navigationTitle(displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(forcesDark ? .dark : nil)
        .task(id: locale) {
            if model == nil {
                model = PageModel(client: app.client, slug: slug)
            }
            await model?.load(locale: locale)
        }
    }

    private var loadedPage: PageDocument? {
        guard let model, case .loaded(let page) = model.state else { return nil }
        return page
    }

    private var displayTitle: String {
        loadedPage?.title ?? title
    }

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
                Task { await model.load(locale: locale) }
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
                VStack(alignment: .leading, spacing: Spacing.s4) {
                    if showsLanguagePicker {
                        HStack {
                            Spacer(minLength: 0)
                            LanguagePicker(locale: locale.rawValue) { code in
                                storedLocale = code
                            }
                        }
                        .padding(.horizontal, PageLayout.gutter)
                    }

                    BlokListView(page.body, appliesPageGutter: true)
                }
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

    func load(locale: AppLocale = .en) async {
        state = .loading
        do {
            state = .loaded(try await client.page(slug: slug, locale: locale))
        } catch let error as ContentError {
            state = .failed(error)
        } catch {
            state = .failed(.transport(error.localizedDescription))
        }
    }
}

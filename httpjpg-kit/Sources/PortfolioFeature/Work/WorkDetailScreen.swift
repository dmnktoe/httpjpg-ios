import DesignSystem
import StoryblokContent
import StoryblokCore
import SwiftUI
import Tokens

struct WorkDetailScreen: View {
    let route: WorkRoute

    @Environment(AppModel.self) private var app
    @Environment(\.bottomBarClearance) private var bottomBarClearance
    @Environment(\.openURL) private var openURL
    @Environment(\.pageTheme) private var ambientTheme

    @State private var model: WorkDetailModel?
    @State private var imageTint = FeaturedChromeTint()

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                LoadingState()
            }
        }
        .pageSurface(forcingDark: pageIsDark)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(forcesDark ? .dark : nil)
        .modifier(DetailChromeAccent(color: imageTint.color, onAccent: imageTint.onColor))
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if let url = externalPreviewURL {
                    Button {
                        openURL(url)
                    } label: {
                        Label("Open external preview", systemImage: "safari")
                    }
                    .tint(theme.foreground)
                }

                ShareLink(item: shareURL)
                    .tint(theme.foreground)
            }
        }
        .task {
            if model == nil {
                model = WorkDetailModel(client: app.client, slug: route.slug)
                Telemetry.signal("work.detail.viewed", parameters: ["slug": route.slug])
                await model?.load()
            }
        }
        .task(id: loadedDetail?.id) {
            imageTint.update(url: FeaturedChromeTint.sampleURL(for: loadedDetail))
        }
    }

    private var externalPreviewURL: URL? {
        loadedDetail != nil
            ? validated(loadedDetail?.link?.resolvedURL(siteOrigin: app.configuration.siteOrigin))
            : validated(route.previewURL)
    }

    private func validated(_ url: URL?) -> URL? {
        guard let url,
              url.scheme == "https" || url.scheme == "http",
              url.host != app.configuration.siteOrigin.host
        else { return nil }
        return url
    }

    private var loadedDetail: WorkDetail? {
        guard let model, case .loaded(let detail) = model.state else { return nil }
        return detail
    }

    private var pageIsDark: Bool {
        loadedDetail?.isDark ?? route.isDark
    }

    private var theme: PageTheme {
        pageIsDark ? .dark : ambientTheme
    }

    private var forcesDark: Bool {
        pageIsDark && app.selectedTab == .work && app.workPath.last?.slug == route.slug
    }

    private var navigationTitle: String {
        loadedDetail?.title ?? route.title
    }

    private var shareURL: URL {
        loadedDetail?.canonicalURL(siteOrigin: app.configuration.siteOrigin)
            ?? app.configuration.siteOrigin.appending(path: StorySlug.workPrefix + route.slug)
    }

    @ViewBuilder
    private func content(_ model: WorkDetailModel) -> some View {
        switch model.state {
        case .loading:
            LoadingState(label: route.slug)
        case .failed(let error):
            AsciiState(
                art: error.isNotFound ? Ascii.notFound : Ascii.error,
                label: error.isNotFound ? "Not found" : "Something broke",
                message: error.errorDescription
            ) {
                Task { await model.load() }
            }
        case .loaded(let detail):
            loaded(detail)
        }
    }

    private func loaded(_ detail: WorkDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                BlokListView(detail.body, appliesPageGutter: true)

                if detail.body.isEmpty {
                    fallbackBody(detail)
                        .padding(.horizontal, PageLayout.gutter)
                }
            }
            .padding(.top, Spacing.s6)
            .padding(.bottom, bottomBarClearance)
        }
        .softScrollEdges()
    }

    @ViewBuilder
    private func fallbackBody(_ detail: WorkDetail) -> some View {
        Headline(detail.title, level: .two)
        StoryRichText(detail.details)
        ForEach(Array(detail.images.enumerated()), id: \.offset) { entry in
            AssetImage(asset: entry.element, fallbackAlt: detail.title)
        }
    }
}

/// Applies chrome accent only once a still has been sampled, so we don't wipe the parent tint while loading.
private struct DetailChromeAccent: ViewModifier {
    let color: Color?
    let onAccent: Color?

    func body(content: Content) -> some View {
        if let color {
            content.chromeAccent(color, onAccent: onAccent)
        } else {
            content
        }
    }
}

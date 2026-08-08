import DesignSystem
import StoryblokContent
import SwiftUI

struct WorkDetailScreen: View {
    let route: WorkRoute

    @Environment(AppModel.self) private var app
    @Environment(\.bottomBarClearance) private var bottomBarClearance
    @Environment(\.openURL) private var openURL
    @Environment(\.pageTheme) private var ambientTheme

    @State private var model: WorkDetailModel?

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
        // toolbarColorScheme doesn't reach the status bar when the bar is
        // transparent; forcing the scheme does. Tied to the selected tab and
        // the top of the path: the stack stays mounted across tab switches,
        // and coupling to the path flips the scene when a pop starts instead
        // of snapping after the pop animation finishes.
        .preferredColorScheme(forcesDark ? .dark : nil)
        .toolbar {
            // One group, one glass cluster: the external preview lives next
            // to the share button instead of in the bottom pill row, so it
            // appears and leaves with the screen — no choreography of its own.
            ToolbarItemGroup(placement: .topBarTrailing) {
                // Monochrome on purpose: iOS forces bar items to monochrome
                // once content scrolls beneath the glass, so a colored tint
                // (the global link tint) visibly flipped on the first scroll.
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
    }

    // The route carries the link the index payload already knows, so the
    // button is there from the first frame; once the detail is loaded its
    // own link is the truth (the field may have been cleared since).
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

    // The route's hint bridges the load; the loaded detail is the truth.
    private var pageIsDark: Bool {
        loadedDetail?.isDark ?? route.isDark
    }

    /// The theme this page renders in, ahead of the ambient one catching up
    /// through the scene flip — bar items tinted off the ambient theme were
    /// black-on-dark for the first second.
    private var theme: PageTheme {
        pageIsDark ? .dark : ambientTheme
    }

    private var forcesDark: Bool {
        pageIsDark && app.selectedTab == .work && app.workPath.last?.slug == route.slug
    }

    private var navigationTitle: String {
        loadedDetail?.title ?? route.title
    }

    // Derived from the route, not the loaded detail, so the button is there
    // from the first frame — conditional toolbar items pop in unanimated.
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

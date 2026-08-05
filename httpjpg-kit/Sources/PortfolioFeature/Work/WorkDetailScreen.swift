import DesignSystem
import StoryblokContent
import SwiftUI

struct WorkDetailScreen: View {
    let route: WorkRoute

    @Environment(AppModel.self) private var app
    @Environment(\.bottomBarClearance) private var bottomBarClearance
    @Environment(\.openURL) private var openURL

    @State private var model: WorkDetailModel?

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                LoadingState()
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        // toolbarColorScheme doesn't reach the status bar when the bar is
        // transparent; forcing the scheme does. Tied to the selected tab
        // because the stack stays mounted across tab switches — a hidden
        // dark page must not keep the whole scene dark.
        .preferredColorScheme(forcesDark ? .dark : nil)
        .toolbar {
            // One group, one glass cluster: the external preview lives next
            // to the share button instead of in the bottom pill row, so it
            // appears and leaves with the screen — no choreography of its own.
            ToolbarItemGroup(placement: .topBarTrailing) {
                if let url = externalPreviewURL {
                    Button {
                        openURL(url)
                    } label: {
                        Text("↗")
                            .font(Typography.mono(Typography.Size.md, weight: .bold))
                    }
                    .accessibilityLabel("Open external preview")
                }

                ShareLink(item: shareURL)
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

    private var forcesDark: Bool {
        loadedDetail?.isDark == true && app.selectedTab == .work
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
        .pageSurface(forcingDark: detail.isDark)
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

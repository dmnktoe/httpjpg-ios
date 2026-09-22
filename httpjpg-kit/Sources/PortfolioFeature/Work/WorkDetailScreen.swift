import DesignSystem
import StoryblokContent
import StoryblokCore
import SwiftUI
import Tokens

private struct WorkDetailLoadID: Hashable {
    let slug: String
    let token: Int
}

struct WorkDetailScreen: View {
    let route: WorkRoute

    @Environment(AppModel.self) private var app
    @Environment(\.bottomBarClearance) private var bottomBarClearance
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    @Environment(\.pageTheme) private var theme

    @State private var model: WorkDetailModel?
    @State private var imageViewerHeld = false
    /// Cleared while an interactive pop is in flight so `preferredColorScheme`
    /// does not keep painting the work list black under the gesture.
    @State private var isInteractivelyPopping = false

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
        .navigationBarBackButtonHidden(true)
        .enablesInteractivePopGesture { phase in
            switch phase {
            case .began, .completed:
                isInteractivelyPopping = true
            case .cancelled:
                isInteractivelyPopping = false
            }
        }
        // Forced-dark pages pin the scene for the status bar. Clearing to
        // `nil` on pop leaves the window stuck dark on current iOS, so an
        // interactive swipe restores the ambient scheme explicitly; the root
        // page theme also ignores this override so the list stays put.
        .preferredColorScheme(sceneColorScheme)
        .chromeAccent(chromeTint, onAccent: chromeOnTint)
        .onPreferenceChange(ImageViewerHeldKey.self) { imageViewerHeld = $0 }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                }
                .toolbarGlassButton(chromeTint, fallback: orbTint)
                .disabled(imageViewerHeld)
                .accessibilityLabel("Back")
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                if let url = externalPreviewURL {
                    Button { openURL(url) } label: {
                        Image(systemName: "safari")
                    }
                    .toolbarGlassButton(chromeTint, fallback: orbTint)
                    .disabled(imageViewerHeld)
                    .accessibilityLabel("Open external preview")
                }

                ShareLink(item: shareURL) {
                    Image(systemName: "square.and.arrow.up")
                }
                .toolbarGlassButton(chromeTint, fallback: orbTint)
                .disabled(imageViewerHeld)
                .accessibilityLabel("Share")
            }
        }
        .task(id: WorkDetailLoadID(slug: route.slug, token: app.workRouteToken)) {
            model = WorkDetailModel(client: app.client, slug: route.slug)
            Telemetry.signal("work.detail.viewed", parameters: ["slug": route.slug])
            await model?.load()
            await app.workIndex.load()
        }
    }

    private var indexItem: WorkItem? {
        app.workIndex.allWork.first { $0.slug == route.slug }
    }

    /// Prefer the loaded detail, then the index card, then the route payload.
    private var accentToken: String? {
        loadedDetail?.accentColor ?? indexItem?.accentColor ?? route.accentColor
    }

    private var chromeTint: Color? {
        Palette.named(accentToken)
    }

    private var chromeOnTint: Color? {
        Palette.onNamed(accentToken)
    }

    private var orbTint: PillTint {
        .control(headerTheme, accent: chromeTint, onAccent: chromeOnTint)
    }

    /// The page forces its own appearance, so the toolbar has to be tinted
    /// against that theme rather than the ambient one.
    private var headerTheme: PageTheme {
        pageIsDark ? .dark : theme
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

    private var forcesDark: Bool {
        pageIsDark && app.selectedTab == .work && app.workPath.last?.slug == route.slug
    }

    private var pinsSceneDark: Bool {
        forcesDark && !isInteractivelyPopping
    }

    /// `nil` only when this page never forced dark — otherwise restore the
    /// ambient scheme so a pop does not leave the window stuck black.
    private var sceneColorScheme: ColorScheme? {
        if pinsSceneDark { return .dark }
        return pageIsDark ? theme.colorScheme : nil
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

                if app.config.features.isRelatedWorkEnabled {
                    RelatedWorkSection(
                        tags: detail.tags,
                        matches: RelatedWork.neighbours(
                            id: detail.id,
                            tagValues: detail.tagValues,
                            in: app.workIndex.allWork
                        )
                    )
                    .padding(.horizontal, PageLayout.gutter)
                }

                if app.config.features.isPrevNextWorkEnabled {
                    let adjacent = AdjacentWork.neighbours(for: route.slug, in: app.workIndex.allWork)
                    WorkNavSection(previous: adjacent.prev, next: adjacent.next)
                        .padding(.horizontal, PageLayout.gutter)
                }
            }
            .padding(.top, Spacing.s6)
            .padding(.bottom, bottomBarClearance)
        }
        // Hard top: system bar rule appears once content scrolls under the
        // title. Soft on top dissolves that rule for good (index/drawer only).
        .navigationScrollEdges()
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

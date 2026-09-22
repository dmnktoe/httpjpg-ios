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

    /// Shares a morph identity across the three toolbar orbs so they travel as
    /// one piece of glass when the trailing pair appears or the share sheet
    /// takes over.
    @Namespace private var toolbarGlass

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
        .preferredColorScheme(forcesDark ? .dark : nil)
        .chromeAccent(chromeTint, onAccent: chromeOnTint)
        .navigationBarBackground(headerBackground, scheme: headerScheme)
        .onPreferenceChange(ImageViewerHeldKey.self) { imageViewerHeld = $0 }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.glassOrb(orbTint, morphID: "back", in: toolbarGlass))
                .disabled(imageViewerHeld)
                .accessibilityLabel("Back")
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                if let url = externalPreviewURL {
                    Button { openURL(url) } label: {
                        Image(systemName: "safari")
                    }
                    .buttonStyle(.glassOrb(orbTint, morphID: "preview", in: toolbarGlass))
                    .disabled(imageViewerHeld)
                    .accessibilityLabel("Open external preview")
                }

                ShareLink(item: shareURL) {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.glassOrb(orbTint, morphID: "share", in: toolbarGlass))
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

    /// iOS 26 left every bar as clear glass, which put an accented page's header
    /// over its own artwork with nothing behind the title. An accented page
    /// paints the bar; an unaccented one keeps the system glass.
    private var headerBackground: Color? {
        guard let chromeTint else { return nil }
        return chromeTint.opacity(Self.headerFillOpacity)
    }

    private var headerScheme: ColorScheme? {
        // The title follows the same contrast call the toolbar glyphs made, so
        // the bar never mixes a black title with white buttons.
        guard let prefersLight = Palette.prefersLightForeground(accentToken) else {
            return pageIsDark ? .dark : nil
        }
        return prefersLight ? .dark : .light
    }

    /// Enough accent to read as the page's colour, sheer enough that the content
    /// scrolling under it still shows through.
    private static let headerFillOpacity: Double = 0.82

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

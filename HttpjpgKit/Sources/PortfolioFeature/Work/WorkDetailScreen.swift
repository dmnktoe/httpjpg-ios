import DesignSystem
import StoryblokContent
import SwiftUI

/// A single work story — the app's `/work/[slug]`.
///
/// The page is its `body` bloks, exactly as on the web. The story's `images`
/// field is *not* rendered here: it feeds the index card, and the images that
/// belong to the page are already `image` bloks inside the body. Rendering
/// both duplicated every photo and stacked two titles on top of each other.
///
/// This screen also uses the *system* navigation bar rather than a custom
/// header. Hiding the bar takes the interactive pop gesture with it — UIKit
/// hangs swipe-back off the navigation bar — and on iOS 26 the system bar is
/// already Liquid Glass.
struct WorkDetailScreen: View {
    let route: WorkRoute

    @Environment(AppModel.self) private var app

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
        .toolbar {
            if let shareURL {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: shareURL)
                }
            }
        }
        .task {
            if model == nil {
                model = WorkDetailModel(client: app.client, slug: route.slug)
                await model?.load()
            }
            // The cancellation check keeps a swipe-back during loading from
            // resurrecting the pill after `onDisappear` already cleared it.
            if !Task.isCancelled {
                app.previewURL = externalPreviewURL
                app.storyTheme = loadedDetail?.isDark == true ? .dark : nil
            }
        }
        .onDisappear {
            app.previewURL = nil
            app.storyTheme = nil
        }
    }

    /// What the web's floating preview badge points at: the story's own link,
    /// and only when it leads off-site — an internal story link is navigation,
    /// not a preview.
    private var externalPreviewURL: URL? {
        guard let url = loadedDetail?.link?.resolvedURL(siteOrigin: app.configuration.siteOrigin),
              url.scheme == "https" || url.scheme == "http",
              url.host != app.configuration.siteOrigin.host
        else { return nil }
        return url
    }

    private var loadedDetail: WorkDetail? {
        guard let model, case .loaded(let detail) = model.state else { return nil }
        return detail
    }

    private var navigationTitle: String {
        loadedDetail?.title ?? route.title
    }

    private var shareURL: URL? {
        loadedDetail?.canonicalURL(siteOrigin: app.configuration.siteOrigin)
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
        // A story can opt into the dark page theme via `isDark`, exactly as
        // `page-theme.ts` resolves it on the web.
        let theme = detail.isDark ? PageTheme.dark : PageTheme.light
        return ScrollView {
            VStack(alignment: .leading, spacing: Spacing.s6) {
                Meta(detail: detail)
                    .padding(.horizontal, PageLayout.gutter)

                // The body carries its own headlines, so the story title is
                // left to the navigation bar rather than repeated here. It
                // also carries its own gutter when it starts with a container.
                BlokListView(detail.body, appliesPageGutter: true)

                if detail.body.isEmpty {
                    fallbackBody(detail)
                        .padding(.horizontal, PageLayout.gutter)
                }

                if let link = detail.link,
                   let url = link.resolvedURL(siteOrigin: app.configuration.siteOrigin) {
                    Link(destination: url) {
                        Text("visit ↗")
                    }
                    .buttonStyle(.brutal(variant: .primary, size: .md))
                    .padding(.horizontal, PageLayout.gutter)
                }
            }
            .padding(.top, Spacing.s6)
            .padding(.bottom, TabBarClearance.bottomPadding)
        }
        .pageTheme(theme)
        .pageSurface(theme)
    }

    /// Older stories predate the body-blok layout and carry only a title,
    /// a description and the asset field. Without this they would render blank.
    @ViewBuilder
    private func fallbackBody(_ detail: WorkDetail) -> some View {
        Headline(detail.title, level: .two)
        StoryRichText(detail.details)
        ForEach(Array(detail.images.enumerated()), id: \.offset) { entry in
            AssetImage(asset: entry.element, fallbackAlt: detail.title)
        }
    }
}

/// Date and tape. No tag chips: every project carries the same tag, so the row
/// said nothing and cost a line at the top of every story.
private struct Meta: View {
    let detail: WorkDetail

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            if let date = detail.date {
                WorkCardDateView(date: date, dateEnd: detail.dateEnd)
            }
            AsciiTape()
        }
    }
}

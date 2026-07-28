import DesignSystem
import Observation
import StoryblokContent
import SwiftUI

/// The info tab: everything on the site that isn't work.
///
/// It used to point at the `home` story, which was a mistake — on the web
/// `home` *is* the work index, so the tab either duplicated the first one or
/// rendered blank. There is no canonical "about" slug to point at instead, so
/// the pages are discovered: every story outside `work/`, listed, opened
/// through the same blok registry the web uses.
struct InfoScreen: View {
    @Environment(AppModel.self) private var app

    @State private var model: InfoModel?
    @State private var path: [PageRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let model {
                    content(model)
                } else {
                    LoadingState()
                }
            }
            .navigationDestination(for: PageRoute.self) { route in
                PageScreen(slug: route.slug, title: route.title)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task {
            if model == nil {
                model = InfoModel(client: app.client)
                await model?.load()
            }
        }
    }

    @ViewBuilder
    private func content(_ model: InfoModel) -> some View {
        switch model.state {
        case .loading:
            LoadingState(label: "fetching pages")
        case .failed(let message):
            AsciiState(art: Ascii.offline, label: "Could not load pages", message: message) {
                Task { await model.load() }
            }
        case .loaded(let pages) where pages.isEmpty:
            AsciiState(art: Ascii.empty, label: "No pages")
        case .loaded(let pages):
            list(pages, model: model)
        }
    }

    private func list(_ pages: [PageSummary], model: InfoModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                MonoText(
                    "⇝ᵣₑcꫀₙₜ pages",
                    size: Typography.Size.sm,
                    tracking: Typography.Size.sm * 0.1,
                    opacity: Opacities.muted
                )
                .padding(.bottom, Spacing.s4)

                ForEach(pages) { page in
                    NavigationLink(value: PageRoute(page: page)) {
                        PageRow(page: page)
                    }
                    .buttonStyle(.plain)
                    BrutalDivider(variant: .dotted)
                }

                AsciiArt(Ascii.sparkles, label: "", size: Typography.Size.xs, opacity: Opacities.dimmed)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, Spacing.s8)
            }
            .padding(.horizontal, PageLayout.gutter)
            .padding(.vertical, Spacing.s6)
        }
        .refreshable { await model.load() }
    }
}

private struct PageRow: View {
    let page: PageSummary

    @Environment(\.pageTheme) private var theme

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s3) {
            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(page.title)
                    .font(Typography.sansBold(Typography.Size.base))
                    .multilineTextAlignment(.leading)
                MonoText("/\(page.slug)", size: Typography.Size.xs, opacity: Opacities.subtle)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 0)
            MonoText("↳", size: Typography.Size.sm)
                .foregroundStyle(theme.link)
        }
        .padding(.vertical, Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

/// A page destination. Carries the title so the pushed screen has something to
/// show in its navigation bar before the story arrives.
struct PageRoute: Hashable {
    let slug: String
    let title: String

    init(page: PageSummary) {
        slug = page.slug
        title = page.title
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

import DesignSystem
import StoryblokContent
import SwiftUI

/// A single work story — the app's `/work/[slug]`.
struct WorkDetailScreen: View {
    let route: WorkRoute

    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.pageTheme) private var inheritedTheme

    @State private var model: WorkDetailModel?

    var body: some View {
        Group {
            if let model {
                content(model)
            } else {
                LoadingState()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if model == nil {
                model = WorkDetailModel(client: app.client, slug: route.slug)
                await model?.load()
            }
        }
    }

    @ViewBuilder
    private func content(_ model: WorkDetailModel) -> some View {
        switch model.state {
        case .loading:
            VStack(spacing: 0) {
                DetailBar(title: route.title, shareURL: nil, onBack: { dismiss() })
                LoadingState(label: route.slug)
            }
        case .failed(let error):
            VStack(spacing: 0) {
                DetailBar(title: route.title, shareURL: nil, onBack: { dismiss() })
                AsciiState(
                    art: error.isNotFound ? Ascii.notFound : Ascii.error,
                    label: error.isNotFound ? "Not found" : "Something broke",
                    message: error.errorDescription
                ) {
                    Task { await model.load() }
                }
            }
        case .loaded(let detail):
            loaded(detail)
        }
    }

    private func loaded(_ detail: WorkDetail) -> some View {
        // A story can opt into the dark page theme via `isDark`, exactly as
        // `page-theme.ts` resolves it on the web.
        let theme = detail.isDark ? PageTheme.dark : inheritedTheme
        return VStack(spacing: 0) {
            DetailBar(
                title: detail.title,
                shareURL: detail.canonicalURL(siteOrigin: app.configuration.siteOrigin),
                onBack: { dismiss() }
            )
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.s6) {
                    Hero(detail: detail)
                    Headline(detail.title, level: .one)
                    Meta(detail: detail)
                    StoryRichText(detail.details)
                    if !detail.body.isEmpty {
                        BlokListView(detail.body)
                    }
                    if let link = detail.link,
                       let url = link.resolvedURL(siteOrigin: app.configuration.siteOrigin) {
                        Link(destination: url) {
                            Text("visit ↗")
                        }
                        .buttonStyle(.brutal(variant: .primary, size: .md))
                    }
                }
                .padding(.horizontal, Layout.gutter)
                .padding(.vertical, Spacing.s6)
            }
        }
        .pageTheme(theme)
        .pageSurface(theme)
    }
}

/// Back / title / share row. Replaces the system navigation bar, which is too
/// soft for this design.
private struct DetailBar: View {
    let title: String
    let shareURL: URL?
    let onBack: () -> Void

    @Environment(\.pageTheme) private var theme

    var body: some View {
        HStack(spacing: Spacing.s3) {
            Button(action: onBack) {
                Text("← back")
                    .font(Typography.mono(Typography.Size.sm))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Spacer(minLength: Spacing.s2)

            if let shareURL {
                ShareLink(item: shareURL) {
                    Text("share ↗")
                        .font(Typography.mono(Typography.Size.sm))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Layout.gutter)
        .padding(.vertical, Spacing.s3)
        .overlay(alignment: .bottom) {
            Rectangle().fill(theme.foreground).frame(height: 1)
        }
    }
}

private struct Hero: View {
    let detail: WorkDetail

    var body: some View {
        if detail.images.isEmpty {
            EmptyView()
        } else {
            TabView {
                ForEach(Array(detail.images.enumerated()), id: \.offset) { entry in
                    AssetImage(asset: entry.element, fallbackAlt: detail.title, aspectRatio: 4.0 / 3.0)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: detail.images.count > 1 ? .automatic : .never))
            .aspectRatio(4.0 / 3.0, contentMode: .fit)
        }
    }
}

private struct Meta: View {
    let detail: WorkDetail

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            if let date = detail.date {
                WorkCardDateView(date: date, dateEnd: detail.dateEnd)
            }
            AsciiTape()
            if !detail.tags.isEmpty {
                TagChipRow(tags: detail.tags)
            }
        }
    }
}

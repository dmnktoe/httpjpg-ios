import DesignSystem
import StoryblokContent
import SwiftUI

/// The work index — the app's home screen, matching `/` on the web.
struct WorkIndexScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.displayScale) private var displayScale

    @State private var model: WorkIndexModel?

    var body: some View {
        // The path lives on `AppModel` so a widget tap can push a story before
        // this screen has appeared.
        @Bindable var app = app
        return NavigationStack(path: $app.workPath) {
            Group {
                if let model {
                    content(model)
                } else {
                    LoadingState()
                }
            }
            // The site name is drawn in the scroll content instead of as a
            // large title: it is long enough to need two lines, and the large
            // title is single-line by construction, so it truncated mid-word
            // and reserved a whole bar's worth of height to do it. The bar
            // itself stays — it carries the scroll-edge glass and the
            // interactive pop gesture — just without a title of its own.
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: WorkRoute.self) { route in
                WorkDetailScreen(route: route)
            }
        }
        .task {
            if model == nil {
                model = WorkIndexModel(client: app.client)
            }
            await model?.load()
        }
    }

    @ViewBuilder
    private func content(_ model: WorkIndexModel) -> some View {
        switch model.state {
        case .idle, .loading:
            LoadingState(label: "fetching work")
        case .failed(let message):
            AsciiState(art: Ascii.offline, label: "Could not load work", message: message) {
                Task { await model.load(force: true) }
            }
        case .loaded:
            list(model)
        }
    }

    private func list(_ model: WorkIndexModel) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.s8) {
                masthead(model)

                if model.visibleItems.isEmpty {
                    AsciiState(art: Ascii.empty, label: "Nothing here yet")
                        .frame(minHeight: 240)
                } else {
                    ForEach(model.visibleItems) { item in
                        row(for: item)
                    }
                }
            }
            .padding(.horizontal, PageLayout.gutter)
            .padding(.bottom, Spacing.s8)
        }
        .refreshable { await model.load(force: true) }
    }

    /// Title and slice switch, kept as one tight group so the gap between them
    /// reads as one header rather than two floating rows.
    private func masthead(_ model: WorkIndexModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Headline(app.siteName, level: .two)
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            VariantPicker(
                links: app.config.headerMenu,
                selection: model.variant,
                onSelect: { model.select(variant: $0) }
            )

            if !model.availableTags.isEmpty {
                TagChipRow(
                    tags: model.availableTags,
                    selected: model.selectedTags,
                    onSelect: { model.toggle(tag: $0) }
                )
            }
        }
        .padding(.top, Spacing.s2)
    }

    /// External-only entries link straight out, exactly as they do on the web.
    @ViewBuilder
    private func row(for item: WorkItem) -> some View {
        let card = WorkCardAdapter.model(
            for: item,
            targetWidth: PageLayout.cardWidth(viewport: viewportWidth),
            scale: displayScale
        )
        if item.isExternal, let url = item.externalURL {
            Link(destination: url) {
                WorkCardView(card)
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(value: WorkRoute(item: item)) {
                WorkCardView(card)
            }
            .buttonStyle(.plain)
        }
    }
}

/// The Projects / Websites switch, built from the CMS header menu.
private struct VariantPicker: View {
    let links: [MenuLink]
    let selection: MenuLink.Variant
    let onSelect: (MenuLink.Variant) -> Void

    @Environment(\.pageTheme) private var theme

    var body: some View {
        HStack(spacing: Spacing.s4) {
            ForEach(entries) { link in
                Button {
                    onSelect(link.variant)
                } label: {
                    Text(link.label.lowercased())
                        .font(Typography.mono(
                            Typography.Size.md,
                            weight: link.variant == selection ? .bold : .regular
                        ))
                        .tracking(Typography.Size.md * 0.05)
                        .opacity(link.variant == selection ? 1 : Opacities.subtle)
                        .overlay(alignment: .bottom) {
                            if link.variant == selection {
                                Rectangle()
                                    .fill(theme.foreground)
                                    .frame(height: 2)
                                    .offset(y: 4)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(link.variant == selection ? [.isSelected, .isButton] : .isButton)
            }
            Spacer(minLength: 0)
        }
    }

    /// One entry per variant. The CMS can list several links per variant; the
    /// first one wins, and a missing variant falls back to its own name.
    private var entries: [MenuLink] {
        MenuLink.Variant.allVariants.map { variant in
            links.first { $0.variant == variant }
                ?? MenuLink(id: variant.rawValue, label: variant.rawValue, variant: variant, link: nil)
        }
    }
}

extension MenuLink.Variant {
    static let allVariants: [MenuLink.Variant] = [.projects, .websites]
}

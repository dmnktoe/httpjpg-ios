import DesignSystem
import StoryblokContent
import SwiftUI

/// The work index — the app's home screen, matching `/` on the web.
struct WorkIndexScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.displayScale) private var displayScale

    @State private var model: WorkIndexModel?
    @State private var path: [WorkRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let model {
                    content(model)
                } else {
                    LoadingState()
                }
            }
            .navigationDestination(for: WorkRoute.self) { route in
                WorkDetailScreen(route: route)
            }
            .toolbar(.hidden, for: .navigationBar)
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
            LazyVStack(alignment: .leading, spacing: Spacing.s10) {
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
            .padding(.vertical, Spacing.s6)
        }
        .refreshable { await model.load(force: true) }
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

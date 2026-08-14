import DesignSystem
import StoryblokContent
import StoryblokCore
import SwiftUI
import Tokens

struct WorkIndexScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.displayScale) private var displayScale
    @Environment(\.bottomBarClearance) private var bottomBarClearance

    @Namespace private var cardZoom

    var body: some View {
        @Bindable var app = app
        return NavigationStack(path: $app.workPath) {
            content(app.workIndex)
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .sidebarMenuToolbar()
                .navigationDestination(for: WorkRoute.self) { route in
                    WorkDetailScreen(route: route)
                        .zoomTransitionDestination(id: route.slug, in: cardZoom)
                }
        }
        .task {
            Telemetry.signal("work.index.viewed")
            await app.workIndex.load()
        }
    }

    @ViewBuilder
    private func content(_ model: WorkIndexModel) -> some View {
        switch model.state {
        case .failed(let message):
            AsciiState(art: Ascii.offline, label: "Could not load work", message: message) {
                Task { await model.load(force: true) }
            }
        case .idle, .loading, .loaded:
            list(model)
        }
    }

    private func list(_ model: WorkIndexModel) -> some View {
        ScrollToTopReader(tick: app.scrollToTopTick(for: .work)) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.s8) {
                    masthead(model)

                    FadeSwap(key: ListGeneration(
                        isLoaded: model.isLoaded,
                        variant: model.variant,
                        tags: model.selectedTags
                    )) {
                        if model.isLoaded {
                            rows(model)
                        } else {
                            WorkListSkeleton()
                        }
                    }
                }
                .padding(.horizontal, PageLayout.gutter)
                .padding(.bottom, bottomBarClearance)
                .scrollToTopAnchor()
            }
            .softScrollEdges()
            .refreshable { await model.load(force: true) }
        }
    }

    @ViewBuilder
    private func rows(_ model: WorkIndexModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            if model.visibleItems.isEmpty {
                AsciiState(art: Ascii.empty, label: "Nothing here yet")
                    .frame(minHeight: 240)
            } else {
                ForEach(Array(model.visibleItems.enumerated()), id: \.element.id) { entry in
                    row(for: entry.element)
                    if entry.offset < model.visibleItems.count - 1 {
                        BrutalDivider(variant: .ascii)
                    }
                }
            }
        }
    }

    private func masthead(_ model: WorkIndexModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Headline(app.siteName, level: .two, lineSpacing: -0.45)
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
                    counts: model.tagCounts,
                    selected: model.selectedTags,
                    onSelect: { model.toggle(tag: $0) }
                )
                .sensoryFeedback(.selection, trigger: model.selectedTags)
            }
        }
        .padding(.top, Spacing.s2)
        .animation(Motion.stateChange, value: model.availableTags)
    }

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
            .workCardMenu(for: item)
        } else {
            NavigationLink(value: WorkRoute(item: item)) {
                WorkCardView(card)
            }
            .buttonStyle(.plain)
            .zoomTransitionSource(id: item.slug, in: cardZoom)
            .workCardMenu(for: item)
        }
    }
}

private struct ListGeneration: Hashable {
    let isLoaded: Bool
    let variant: MenuLink.Variant
    let tags: Set<String>
}

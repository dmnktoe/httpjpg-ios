import DesignSystem
import StoryblokContent
import SwiftUI

struct WorkIndexScreen: View {
    @Environment(AppModel.self) private var app
    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.displayScale) private var displayScale

    @State private var model: WorkIndexModel?

    var body: some View {
        @Bindable var app = app
        return NavigationStack(path: $app.workPath) {
            Group {
                if let model {
                    content(model)
                } else {
                    LoadingState()
                }
            }

            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: WorkRoute.self) { route in
                WorkDetailScreen(route: route)
            }
        }
        .task {
            if model == nil {
                model = WorkIndexModel(client: app.client)
                Telemetry.signal("work.index.viewed")
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

                FadeInUp {
                    rows(model)
                }
                .id(filterFingerprint(model))
            }
            .padding(.horizontal, PageLayout.gutter)
            .padding(.bottom, TabBarClearance.bottomPadding)
        }
        .refreshable { await model.load(force: true) }
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

    private func filterFingerprint(_ model: WorkIndexModel) -> String {
        model.variant.rawValue + model.selectedTags.sorted().joined(separator: ",")
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
                    selected: model.selectedTags,
                    onSelect: { model.toggle(tag: $0) }
                )
                .sensoryFeedback(.selection, trigger: model.selectedTags)
            }
        }
        .padding(.top, Spacing.s2)
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
        } else {
            NavigationLink(value: WorkRoute(item: item)) {
                WorkCardView(card)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct FadeInUp<Content: View>: View {
    @ViewBuilder let content: Content

    @State private var isShown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        content
            .opacity(isShown ? 1 : 0)
            .offset(y: isShown ? 0 : 14)
            .onAppear {
                guard !reduceMotion else {
                    isShown = true
                    return
                }
                withAnimation(.easeOut(duration: 0.3)) {
                    isShown = true
                }
            }
    }
}

private struct VariantPicker: View {
    let links: [MenuLink]
    let selection: MenuLink.Variant
    let onSelect: (MenuLink.Variant) -> Void

    @Environment(\.pageTheme) private var theme

    var body: some View {
        HStack(spacing: Spacing.s2) {
            ForEach(entries) { link in
                chip(for: link.variant)
            }
            Spacer(minLength: 0)
        }

        .sensoryFeedback(.selection, trigger: selection)
    }

    private func chip(for variant: MenuLink.Variant) -> some View {
        let isSelected = variant == selection
        let primary = BrutalButtonStyle.Variant.primary

        return Button {
            onSelect(variant)
        } label: {
            Text(variant.filterLabel)
                .font(Typography.mono(Typography.Size.sm))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(isSelected ? primary.label : theme.foreground)
                .padding(.horizontal, Spacing.s3)
                .padding(.vertical, Spacing.s2)
                .contentShape(Capsule())
                .glassBackground(
                    in: .capsule,
                    tint: isSelected ? primary.fill.opacity(0.85) : nil,
                    interactive: true
                )

                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(
                        isSelected
                            ? primary.fill.opacity(0.9)
                            : Palette.neutral.s400.opacity(0.35),
                        lineWidth: 1
                    )
                )
                .opacity(isSelected ? 1 : 0.55)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    private var entries: [MenuLink] {
        MenuLink.Variant.allVariants.map { variant in
            links.first { $0.variant == variant }
                ?? MenuLink(id: variant.rawValue, label: variant.rawValue, variant: variant, link: nil)
        }
    }
}

extension MenuLink.Variant {
    static let allVariants: [MenuLink.Variant] = [.projects, .websites]

    var filterLabel: String {
        switch self {
        case .projects: return "⇝ᵣₑcꫀₙₜ TH1𝓃𝑔S"
        case .websites: return "⇝ᵣₑcꫀₙₜ ℘ɑׁׅ֮ᧁׁꫀׁׅܻ꯱ׁׅ֒"
        }
    }
}

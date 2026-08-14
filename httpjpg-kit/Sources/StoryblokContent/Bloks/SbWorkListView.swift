import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

public struct SbWorkListView: View {
    private let blok: WorkListBlok

    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.displayScale) private var displayScale
    @Environment(\.contentClient) private var client

    @State private var fetchedItems: [WorkItem]?
    @State private var selectedTags: Set<String> = []

    public init(blok: WorkListBlok) {
        self.blok = blok
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            if blok.showsTagFilter, !availableTags.isEmpty {
                TagChipRow(
                    tags: availableTags,
                    counts: tagCounts,
                    selected: selectedTags,
                    onSelect: { tag in
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                    }
                )
            }

            ForEach(Array(visibleModels.enumerated()), id: \.element.id) { entry in
                NavigationLink(value: route(for: entry.element)) {
                    WorkCardView(entry.element, variant: cardVariant)
                }
                .buttonStyle(.plain)

                if blok.showsDividers, entry.offset < visibleModels.count - 1 {
                    BrutalDivider(
                        variant: BrutalDivider.Variant(rawValue: blok.dividerVariant) ?? .solid,
                        pattern: blok.dividerPattern ?? Ascii.dividerStars
                    )
                }
            }
        }
        .blokSpacing(blok.spacing)
        .task(id: blok.id) {
            guard needsFetch, let client else { return }
            guard let stories = try? await client.workStories(byUUIDs: blok.workUUIDs) else { return }
            guard !Task.isCancelled else { return }
            fetchedItems = stories.map(WorkItem.init(story:))
        }
    }

    private var needsFetch: Bool {
        blok.work.isEmpty && !blok.workUUIDs.isEmpty && fetchedItems == nil
    }

    private func route(for model: WorkCardModel) -> WorkRoute {
        WorkRoute(slug: model.slug, title: model.title, previewURL: model.externalURL)
    }

    private var models: [WorkCardModel] {
        if !blok.work.isEmpty {
            return blok.work.compactMap {
                WorkCardAdapter.model(
                    for: $0,
                    targetWidth: PageLayout.cardWidth(viewport: viewportWidth),
                    scale: displayScale
                )
            }
        }
        return (fetchedItems ?? []).map {
            WorkCardAdapter.model(
                for: $0,
                targetWidth: PageLayout.cardWidth(viewport: viewportWidth),
                scale: displayScale
            )
        }
    }

    private var visibleModels: [WorkCardModel] {
        guard !selectedTags.isEmpty else { return models }
        return models.filter { !selectedTags.isDisjoint(with: $0.tags) }
    }

    private var tagCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for model in models {
            for tag in Set(model.tags) {
                counts[tag, default: 0] += 1
            }
        }
        return counts
    }

    private var availableTags: [String] {
        tagCounts
            .sorted { lhs, rhs in
                if lhs.value != rhs.value { return lhs.value > rhs.value }
                return lhs.key.localizedStandardCompare(rhs.key) == .orderedAscending
            }
            .map(\.key)
    }

    private var cardVariant: WorkCardView.Variant {
        WorkCardView.Variant(rawValue: blok.variant) ?? .default
    }
}

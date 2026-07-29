import DesignSystem
import SwiftUI

/// Renders the `work_list` blok.
///
/// The CMS column settings describe a desktop grid; a phone always reads as
/// the stacked variant, which is what `columns: 1` produces on the web too.
///
/// The relation field arrives as bare UUID strings (see the transport note on
/// `ContentClient`), so the cards are fetched here: one `by_uuids_ordered`
/// request when the blok appears, rendered in the order the editor picked.
public struct SbWorkListView: View {
    private let blok: WorkListBlok

    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.displayScale) private var displayScale
    @Environment(\.contentClient) private var client

    @State private var fetchedItems: [WorkItem]?

    public init(blok: WorkListBlok) {
        self.blok = blok
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            ForEach(Array(models.enumerated()), id: \.element.id) { entry in
                NavigationLink(value: WorkRoute(slug: entry.element.slug, title: entry.element.title)) {
                    WorkCardView(entry.element, variant: cardVariant)
                }
                .buttonStyle(.plain)

                if blok.showsDividers, entry.offset < models.count - 1 {
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

    private var cardVariant: WorkCardView.Variant {
        WorkCardView.Variant(rawValue: blok.variant) ?? .default
    }
}

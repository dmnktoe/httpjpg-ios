import DesignSystem
import SwiftUI

/// Renders the `work_list` blok.
///
/// The CMS column settings describe a desktop grid; a phone always reads as
/// the stacked variant, which is what `columns: 1` produces on the web too.
public struct SbWorkListView: View {
    private let blok: WorkListBlok

    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.displayScale) private var displayScale

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
    }

    private var models: [WorkCardModel] {
        blok.work.compactMap {
            WorkCardAdapter.model(
                for: $0,
                targetWidth: Layout.cardWidth(viewport: viewportWidth),
                scale: displayScale
            )
        }
    }

    private var cardVariant: WorkCardView.Variant {
        WorkCardView.Variant(rawValue: blok.variant) ?? .default
    }
}

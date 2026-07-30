import DesignSystem
import SwiftUI

/// Stands in for the work list: two cards at the proportions `WorkCardView` draws, so
/// the real ones land without the page jumping.
struct WorkListSkeleton: View {
    @Environment(\.viewportWidth) private var viewportWidth

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            card
            BrutalDivider(variant: .ascii)
            card
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading work")
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            SkeletonBlock(height: mediaHeight)
            SkeletonBlock(width: 260, height: Typography.Size.xl * 2)
            SkeletonBlock(width: 120, height: Typography.Size.sm)
            SkeletonBlock(width: 180, height: Typography.Size.sm)
                .padding(.top, Spacing.s1)
        }
    }

    private var mediaHeight: CGFloat {
        PageLayout.cardWidth(viewport: viewportWidth) / PageLayout.mediaAspectRatio
    }
}

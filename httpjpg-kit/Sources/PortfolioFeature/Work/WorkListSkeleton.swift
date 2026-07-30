import DesignSystem
import SwiftUI

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

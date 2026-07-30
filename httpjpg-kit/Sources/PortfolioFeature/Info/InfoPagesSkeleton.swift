import DesignSystem
import SwiftUI

/// Stands in for the pages list: the row rhythm and dividers of `InfoPageRow`, at
/// varying widths so it reads as a list rather than a loading bar.
struct InfoPagesSkeleton: View {
    private static let widths: [CGFloat] = [132, 96, 156, 112, 140]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(Self.widths.enumerated()), id: \.offset) { entry in
                VStack(alignment: .leading, spacing: Spacing.s1) {
                    SkeletonBlock(width: entry.element, height: Typography.Size.base)
                    SkeletonBlock(width: entry.element * 0.6, height: Typography.Size.xs)
                }
                .padding(.vertical, Spacing.s3)
                .frame(maxWidth: .infinity, alignment: .leading)

                BrutalDivider(variant: .dotted)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading pages")
    }
}

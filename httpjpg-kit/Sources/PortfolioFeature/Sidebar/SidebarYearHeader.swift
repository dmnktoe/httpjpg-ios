import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

struct SidebarYearHeader: View {
    let group: WorkYearGroup

    @Environment(\.pageTheme) private var theme

    var body: some View {
        HStack(spacing: Spacing.s3) {
            MonoText(
                group.year,
                size: Typography.Size.xs,
                tracking: Typography.Size.xs * 0.2,
                opacity: Opacities.subtle
            )

            BrutalDivider()

            MonoText("\(group.items.count)", size: Typography.Size.xs, opacity: Opacities.dimmed)
        }
        .padding(.horizontal, PageLayout.gutter)
        .padding(.vertical, Spacing.s2)
        // The header pins while its section scrolls, so it needs something
        // opaque behind it.
        .background(theme.drawerBackground)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(group.accessibilityLabel), \(countLabel)")
        .accessibilityAddTraits(.isHeader)
    }

    private var countLabel: String {
        group.items.count == 1 ? "1 project" : "\(group.items.count) projects"
    }
}

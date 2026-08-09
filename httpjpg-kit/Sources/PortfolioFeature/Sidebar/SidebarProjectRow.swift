import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

struct SidebarProjectRow: View {
    let item: WorkItem

    @Environment(\.pageTheme) private var theme

    var body: some View {
        HStack(spacing: Spacing.s3) {
            MonoText(year ?? WorkYearGroup.undatedYear, size: Typography.Size.xs, opacity: Opacities.subtle)

            Marquee(
                item.title,
                font: Typography.uiSans(Typography.Size.base),
                speed: .rate(20),
                repeatCount: 1,
                pauseDuration: 1.5,
                color: theme.foreground
            )
            .frame(maxWidth: .infinity)

            if item.isExternal {
                MonoText("↗", size: Typography.Size.sm, opacity: Opacities.subtle)
            }
        }
        .padding(.vertical, Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(year.map { "\($0), \(item.title)" } ?? item.title)
    }

    private var year: String? {
        item.date.map(WorkCardDate.year(of:))
    }
}

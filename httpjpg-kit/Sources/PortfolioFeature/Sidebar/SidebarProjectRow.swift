import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

struct SidebarProjectRow: View {
    let item: WorkItem

    @Environment(\.pageTheme) private var theme

    var body: some View {
        HStack(spacing: Spacing.s3) {
            Text(item.title)
                .font(Typography.sans(Typography.Size.base))
                .foregroundStyle(theme.foreground)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            if item.isExternal {
                MonoText("↗", size: Typography.Size.sm, opacity: Opacities.subtle)
            }
        }
        .padding(.vertical, Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.title)
    }
}

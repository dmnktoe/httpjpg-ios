import DesignSystem
import StoryblokContent
import SwiftUI

struct SidebarProjectRow: View {
    let item: WorkItem

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s3) {
            Text(item.title)
                .font(Typography.sans(Typography.Size.base))
                .multilineTextAlignment(.leading)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 0)

            if item.isExternal {
                MonoText("↗", size: Typography.Size.sm, opacity: Opacities.subtle)
            }
        }
        .padding(.vertical, Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(.isButton)
    }
}

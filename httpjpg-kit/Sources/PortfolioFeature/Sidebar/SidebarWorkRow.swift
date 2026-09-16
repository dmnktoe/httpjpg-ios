import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

struct SidebarWorkRow: View {
    private static let markerSize = Spacing.s1

    let item: WorkItem

    /// The work the detail stack is showing, marked so the drawer says where
    /// you are rather than only where you can go.
    let isCurrent: Bool

    @Environment(\.pageTheme) private var theme

    var body: some View {
        HStack(spacing: Spacing.s2) {
            marker

            Text(item.title)
                .font(titleFont)
                .foregroundStyle(theme.foreground)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            if item.isExternal {
                MonoText("↗", size: Typography.Size.sm, opacity: Opacities.subtle)
            }
        }
        .padding(.horizontal, PageLayout.gutter)
        .padding(.vertical, Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    /// Always laid out, so marking a row does not shift the titles around it.
    private var marker: some View {
        Circle()
            .fill(isCurrent ? theme.link : Color.clear)
            .frame(width: Self.markerSize, height: Self.markerSize)
            .accessibilityHidden(true)
    }

    private var titleFont: Font {
        isCurrent
            ? Typography.sansBold(Typography.Size.base)
            : Typography.sans(Typography.Size.base)
    }
}

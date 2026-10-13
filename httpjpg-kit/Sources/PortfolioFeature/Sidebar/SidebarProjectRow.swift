import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

struct SidebarProjectRow: View {
    let item: WorkItem

    var isCurrent = false

    @Environment(\.pageTheme) private var theme

    private static let markerWidth: CGFloat = 2

    var body: some View {
        HStack(spacing: Spacing.s3) {
            Text(item.title)
                .font(isCurrent ? Typography.sansBold(Typography.Size.base) : Typography.sans(Typography.Size.base))
                .foregroundStyle(theme.foreground)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            if item.isExternal {
                MonoText(ExternalArrow.glyph, size: Typography.Size.sm, opacity: Opacities.subtle)
            }
        }
        .padding(.vertical, Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .leading) { marker }
        .contentShape(Rectangle())
        .animation(Motion.stateChange, value: isCurrent)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    @ViewBuilder
    private var marker: some View {
        if isCurrent {
            Capsule()
                .fill(theme.link)
                .frame(width: Self.markerWidth)
                .padding(.vertical, Spacing.s2)
                .offset(x: -Spacing.s2)
                .transition(.opacity)
                .accessibilityHidden(true)
        }
    }
}

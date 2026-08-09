import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

struct SidebarYearIndex: View {
    let groups: [WorkYearGroup]
    let onJump: (String) -> Void

    @Environment(\.pageTheme) private var theme

    var body: some View {
        FlowLayout(spacing: Spacing.s2) {
            ForEach(groups) { group in
                Button {
                    onJump(group.year)
                } label: {
                    chip(group.year)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Jump to \(group.accessibilityLabel)")
            }
        }
    }

    private func chip(_ year: String) -> some View {
        Text(year)
            .font(Typography.mono(Typography.Size.xs))
            .tracking(Typography.Size.xs * 0.05)
            .padding(.horizontal, Spacing.s2)
            .padding(.vertical, Spacing.s1 / 2)
            .foregroundStyle(theme.foreground)
            .overlay(Rectangle().stroke(Palette.neutral.s400, lineWidth: 1))
            .opacity(Opacities.muted)
            .contentShape(Rectangle())
    }
}

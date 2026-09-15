import DesignSystem
import SwiftUI
import Tokens

struct NavGlassButton: View {
    let systemName: String
    let label: String
    var tint: Color?
    var onTint: Color?
    let action: () -> Void

    @Environment(\.pageTheme) private var theme

    var body: some View {
        GlassButton(
            shape: .circle,
            tint: tint,
            labelColor: onTint ?? theme.foreground,
            controlSize: .regular,
            accessibilityLabel: label,
            action: action
        ) {
            Image(systemName: systemName)
                .font(.system(size: Typography.Size.md, weight: .semibold))
                .frame(width: Spacing.s9, height: Spacing.s9)
                .contentShape(Circle())
        }
    }
}

struct NavGlassIcon: View {
    let systemName: String
    var tint: Color?
    var onTint: Color?

    @Environment(\.pageTheme) private var theme

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: Typography.Size.md, weight: .semibold))
            .foregroundStyle(onTint ?? theme.foreground)
            .frame(width: Spacing.s9, height: Spacing.s9)
            .contentShape(.circle)
            .glassBackground(in: .circle, tint: tint, interactive: true)
    }
}

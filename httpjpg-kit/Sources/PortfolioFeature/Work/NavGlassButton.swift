import DesignSystem
import SwiftUI
import Tokens

struct NavGlassButton: View {
    private static let diameter: CGFloat = Spacing.s9

    let systemName: String
    let label: String
    var tint: Color?
    var onTint: Color?
    let action: () -> Void

    @Environment(\.pageTheme) private var theme

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: Typography.Size.md, weight: .semibold))
                .foregroundStyle(onTint ?? theme.foreground)
                .frame(width: Self.diameter, height: Self.diameter)
                .contentShape(.circle)
                .glassBackground(
                    in: .circle,
                    tint: tint,
                    interactive: true
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

struct NavGlassIcon: View {
    private static let diameter: CGFloat = Spacing.s9

    let systemName: String
    var tint: Color?
    var onTint: Color?

    @Environment(\.pageTheme) private var theme

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: Typography.Size.md, weight: .semibold))
            .foregroundStyle(onTint ?? theme.foreground)
            .frame(width: Self.diameter, height: Self.diameter)
            .contentShape(.circle)
            .glassBackground(
                in: .circle,
                tint: tint,
                interactive: true
            )
    }
}

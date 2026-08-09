import DesignSystem
import SwiftUI

struct SidebarGlassButton: View {
    let glyph: String
    let label: String
    let action: () -> Void

    private static let diameter: CGFloat = Spacing.s11

    @Environment(\.pageTheme) private var theme
    @State private var taps = 0

    var body: some View {
        Button {
            taps += 1
            action()
        } label: {
            Text(glyph)
                .font(Typography.mono(Typography.Size.base, weight: .medium))
                .foregroundStyle(theme.foreground)
                .frame(width: Self.diameter, height: Self.diameter)
                .contentShape(.circle)
                // No clip and no outline ring on top: both cut off the glass's
                // own specular edge and left it reading as a flat pill.
                .glassBackground(in: .circle, tint: theme.chromeFill, interactive: true)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: taps)
        .accessibilityLabel(label)
    }
}

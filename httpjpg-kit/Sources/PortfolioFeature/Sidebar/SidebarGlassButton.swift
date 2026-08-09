import DesignSystem
import SwiftUI
import Tokens

struct SidebarGlassButton: View {
    let glyph: String
    let label: String
    let action: () -> Void

    private static let diameter: CGFloat = Spacing.s11

    @Environment(\.pageTheme) private var theme

    var body: some View {
        // No haptic of its own: the drawer container ticks on every
        // open/close, whichever control drove it.
        Button(action: action) {
            Text(glyph)
                .font(Typography.mono(Typography.Size.base, weight: .medium))
                .foregroundStyle(theme.foreground)
                .frame(width: Self.diameter, height: Self.diameter)
                .contentShape(.circle)
                .glassBackground(in: .circle, tint: theme.chromeFill, interactive: true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

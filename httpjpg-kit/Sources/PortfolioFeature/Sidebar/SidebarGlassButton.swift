import DesignSystem
import SwiftUI

/// Round liquid-glass button for the top row — the drawer's toggle on the main
/// view, its close button inside the drawer.
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
                .glassBackground(in: .circle, tint: theme.background.opacity(0.4), interactive: true)
                .clipShape(.circle)
                .overlay {
                    Circle().stroke(Palette.neutral.s400.opacity(0.35), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: taps)
        .accessibilityLabel(label)
    }
}

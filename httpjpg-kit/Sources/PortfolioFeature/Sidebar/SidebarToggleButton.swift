import DesignSystem
import SwiftUI
import Tokens

/// The circular glass button that opens the drawer from a screen's toolbar and
/// closes it from the drawer's own header.
struct SidebarToggleButton: View {
    private static let diameter = Spacing.s9

    let systemName: String
    let label: String
    let action: () -> Void

    @Environment(\.pageTheme) private var theme

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: systemName)
                .labelStyle(.iconOnly)
                .font(.system(size: Typography.Size.md, weight: .semibold))
                .foregroundStyle(theme.chromeLabel)
                .frame(width: Self.diameter, height: Self.diameter)
                .contentShape(.circle)
                .glassBackground(in: .circle, tint: theme.chromeFill, interactive: true)
        }
        .buttonStyle(.plain)
    }
}

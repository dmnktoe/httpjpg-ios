import SwiftUI
import Tokens

struct SidebarMenuButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    private static let diameter: CGFloat = Spacing.s9

    @Environment(\.pageTheme) private var theme

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: Typography.Size.md, weight: .semibold))
                .foregroundStyle(theme.background)
                .frame(width: Self.diameter, height: Self.diameter)
                .background(Circle().fill(theme.foreground))
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

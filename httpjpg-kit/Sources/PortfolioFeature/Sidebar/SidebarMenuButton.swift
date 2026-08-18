import SwiftUI
import Tokens

struct SidebarMenuButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    private static let diameter: CGFloat = Spacing.s9

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: Typography.Size.md, weight: .semibold))
                .foregroundStyle(Palette.white)
                .frame(width: Self.diameter, height: Self.diameter)
                .background(Circle().fill(Palette.primary.s500))
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

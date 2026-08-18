import SwiftUI
import Tokens

struct SidebarMenuButton: View {
    enum Style {
        case accent
        case inverse
    }

    let systemName: String
    let label: String
    var style: Style = .accent
    let action: () -> Void

    private static let diameter: CGFloat = Spacing.s9

    @Environment(\.pageTheme) private var theme

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: Typography.Size.md, weight: .semibold))
                .foregroundStyle(glyph)
                .frame(width: Self.diameter, height: Self.diameter)
                .background(Circle().fill(fill))
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var fill: Color {
        switch style {
        case .accent: return Palette.primary.s500
        case .inverse: return theme.foreground
        }
    }

    private var glyph: Color {
        switch style {
        case .accent: return Palette.white
        case .inverse: return theme.background
        }
    }
}

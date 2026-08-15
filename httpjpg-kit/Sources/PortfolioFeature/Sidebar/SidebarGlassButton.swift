import DesignSystem
import SwiftUI
import Tokens

struct SidebarGlassButton: View {
    let glyph: String
    let label: String
    var morphID: AnyHashable? = nil
    let action: () -> Void

    private static let diameter: CGFloat = Spacing.s11

    @Environment(\.pageTheme) private var theme
    @Environment(\.chromeAccent) private var accent
    @Environment(\.glassNamespace) private var glass

    var body: some View {
        Button(action: action) {
            Text(glyph)
                .font(Typography.mono(Typography.Size.base, weight: .medium))
                .foregroundStyle(theme.foreground)
                .frame(width: Self.diameter, height: Self.diameter)
                .contentShape(.circle)
                .glassBackground(in: .circle, tint: theme.chromeFill(accent: accent), interactive: true)
                .modifier(OptionalGlassMorph(id: morphID, glass: glass))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct OptionalGlassMorph: ViewModifier {
    let id: AnyHashable?
    let glass: Namespace.ID?

    func body(content: Content) -> some View {
        if let id, let glass {
            content.glassMorph(id: id, in: glass)
        } else {
            content
        }
    }
}

import DesignSystem
import SwiftUI
import Tokens

struct SidebarMenuToolbar: ViewModifier {
    @Environment(AppModel.self) private var app
    @Environment(\.pageTheme) private var theme
    @Environment(\.chromeAccent) private var accent
    @Environment(\.glassNamespace) private var glass

    private static let diameter: CGFloat = Spacing.s9

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    app.toggleSidebar()
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: Typography.Size.md, weight: .semibold))
                        .foregroundStyle(theme.chromeLabel)
                        .frame(width: Self.diameter, height: Self.diameter)
                        .contentShape(.circle)
                        .glassBackground(in: .circle, tint: theme.chromeFill(accent: accent), interactive: true)
                        .modifier(ToolbarGlassMorph(glass: glass))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open menu")
            }
        }
    }
}

private struct ToolbarGlassMorph: ViewModifier {
    let glass: Namespace.ID?

    func body(content: Content) -> some View {
        if let glass {
            content.glassMorph(id: "sidebar-toggle", in: glass)
        } else {
            content
        }
    }
}

extension View {
    func sidebarMenuToolbar() -> some View {
        modifier(SidebarMenuToolbar())
    }
}

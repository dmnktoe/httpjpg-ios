import DesignSystem
import SwiftUI
import Tokens

struct SidebarMenuToolbar: ViewModifier {
    @Environment(AppModel.self) private var app
    @Environment(\.pageTheme) private var theme

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    app.toggleSidebar()
                } label: {
                    Image(systemName: "line.3.horizontal")
                }
                .toolbarGlassButton(nil, fallback: .control(theme))
                .accessibilityLabel("Open menu")
            }
        }
    }
}

extension View {
    func sidebarMenuToolbar() -> some View {
        modifier(SidebarMenuToolbar())
    }
}

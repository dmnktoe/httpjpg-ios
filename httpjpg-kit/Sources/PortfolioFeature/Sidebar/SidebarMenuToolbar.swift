import SwiftUI

struct SidebarMenuToolbar: ViewModifier {
    @Environment(AppModel.self) private var app

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .topBarLeading) {
                SidebarMenuButton(systemName: "line.3.horizontal", label: "Open menu") {
                    app.toggleSidebar()
                }
            }
        }
    }
}

extension View {
    func sidebarMenuToolbar() -> some View {
        modifier(SidebarMenuToolbar())
    }
}

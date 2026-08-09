import SwiftUI

struct SidebarMenuToolbar: ViewModifier {
    @Environment(AppModel.self) private var app

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .topBarLeading) {
                // No haptic of its own: the drawer container ticks on every
                // open/close, whichever control drove it.
                Button {
                    app.toggleSidebar()
                } label: {
                    Label("Open menu", systemImage: "line.3.horizontal")
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

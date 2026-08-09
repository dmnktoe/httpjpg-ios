import DesignSystem
import SwiftUI

struct SidebarMenuToolbar: ViewModifier {
    @Environment(AppModel.self) private var app

    @State private var taps = 0

    func body(content: Content) -> some View {
        let isSidebarOpen = app.isSidebarOpen

        return content.toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    taps += 1
                    app.toggleSidebar()
                } label: {
                    Label("Open menu", systemImage: "line.3.horizontal")
                }
                .sensoryFeedback(.impact(weight: .light), trigger: taps)
                .opacity(isSidebarOpen ? 0 : 1)
                .disabled(isSidebarOpen)
                .accessibilityHidden(isSidebarOpen)
                .animation(Motion.navigate, value: isSidebarOpen)
            }
        }
    }
}

extension View {
    func sidebarMenuToolbar() -> some View {
        modifier(SidebarMenuToolbar())
    }
}

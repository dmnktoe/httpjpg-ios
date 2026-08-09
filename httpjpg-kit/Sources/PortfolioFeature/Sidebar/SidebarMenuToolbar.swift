import SwiftUI

struct SidebarMenuToolbar: ViewModifier {
    @Environment(AppModel.self) private var app

    @State private var taps = 0

    func body(content: Content) -> some View {
        let isSidebarOpen = app.isSidebarOpen

        return content.toolbar {
            if !isSidebarOpen {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        taps += 1
                        app.toggleSidebar()
                    } label: {
                        Label("Open menu", systemImage: "line.3.horizontal")
                    }
                    .sensoryFeedback(.impact(weight: .light), trigger: taps)
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

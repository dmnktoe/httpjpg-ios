import DesignSystem
import SwiftUI

struct SidebarMenuToolbar: ViewModifier {
    @Environment(AppModel.self) private var app

    @State private var taps = 0

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    taps += 1
                    app.toggleSidebar()
                } label: {
                    Label("Open menu", systemImage: "line.3.horizontal")
                }
                .sensoryFeedback(.impact(weight: .light), trigger: taps)
                // The open drawer carries its own ✕ a few points away, so the
                // two buttons sat almost on top of each other. Fade rather
                // than branch on the toolbar item: removing it makes the bar
                // reflow the title mid-drag.
                .opacity(app.isSidebarOpen ? 0 : 1)
                .allowsHitTesting(!app.isSidebarOpen)
                .accessibilityHidden(app.isSidebarOpen)
                .animation(Motion.drawer, value: app.isSidebarOpen)
            }
        }
    }
}

extension View {
    func sidebarMenuToolbar() -> some View {
        modifier(SidebarMenuToolbar())
    }
}

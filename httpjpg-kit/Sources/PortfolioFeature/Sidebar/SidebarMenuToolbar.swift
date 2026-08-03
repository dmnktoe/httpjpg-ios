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
                    Text("☰")
                        .font(Typography.mono(Typography.Size.base, weight: .medium))
                }
                .sensoryFeedback(.impact(weight: .light), trigger: taps)
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

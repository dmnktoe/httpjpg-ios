import SwiftUI
import Tokens

struct SidebarMenuToolbar: ViewModifier {
    @Environment(AppModel.self) private var app

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    app.toggleSidebar()
                } label: {
                    Label("Open menu", systemImage: "line.3.horizontal")
                        .foregroundStyle(Palette.white)
                }
                .modifier(ProminentMenuButton())
                .tint(Palette.primary.s500)
            }
        }
    }
}

private struct ProminentMenuButton: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glassProminent)
        } else {
            content.buttonStyle(.borderedProminent)
        }
    }
}

extension View {
    func sidebarMenuToolbar() -> some View {
        modifier(SidebarMenuToolbar())
    }
}

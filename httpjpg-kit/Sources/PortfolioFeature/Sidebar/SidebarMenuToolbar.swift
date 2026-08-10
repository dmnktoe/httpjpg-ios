import SwiftUI
import Tokens

struct SidebarMenuToolbar: ViewModifier {
    @Environment(AppModel.self) private var app

    private static let diameter: CGFloat = Spacing.s9

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    app.toggleSidebar()
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: Typography.Size.md, weight: .semibold))
                        .foregroundStyle(Palette.white)
                        .frame(width: Self.diameter, height: Self.diameter)
                        .background(Circle().fill(Palette.primary.s500))
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
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

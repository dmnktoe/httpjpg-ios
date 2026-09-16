import SwiftUI
import Tokens

struct SidebarRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Row(configuration: configuration)
    }

    private struct Row: View {
        let configuration: ButtonStyleConfiguration

        @Environment(\.pageTheme) private var theme

        var body: some View {
            configuration.label
                .background(configuration.isPressed ? theme.border.opacity(Opacities.subtle) : Color.clear)
                .animation(Motion.pressed, value: configuration.isPressed)
        }
    }
}

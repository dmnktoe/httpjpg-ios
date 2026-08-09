import SwiftUI
import Tokens

struct SidebarRowButtonStyle: ButtonStyle {
    @Environment(\.pageTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(theme.foreground.opacity(configuration.isPressed ? 0.08 : 0))
            .animation(Motion.pressed, value: configuration.isPressed)
    }
}

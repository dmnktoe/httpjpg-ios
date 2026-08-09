import SwiftUI
import Tokens

/// Press feedback for drawer rows: a flat wash over the row's own footprint.
/// The stock plain style only dims the label, which disappears against the
/// mono list.
struct SidebarRowButtonStyle: ButtonStyle {
    @Environment(\.pageTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(theme.foreground.opacity(configuration.isPressed ? 0.08 : 0))
            .animation(Motion.pressed, value: configuration.isPressed)
    }
}

import SwiftUI
import Tokens

struct SidebarRowButtonStyle: PrimitiveButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Row(configuration: configuration)
    }

    private struct Row: View {
        let configuration: Configuration

        @Environment(\.pageTheme) private var theme
        @GestureState private var isPressed = false

        var body: some View {
            configuration.label
                .background(theme.foreground.opacity(isPressed ? 0.08 : 0))
                .contentShape(Rectangle())
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: .infinity, maximumDistance: Spacing.s3)
                        .updating($isPressed) { _, state, _ in state = true }
                )
                .onTapGesture { configuration.trigger() }
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { configuration.trigger() }
                .animation(Motion.pressed, value: isPressed)
        }
    }
}

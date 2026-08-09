import SwiftUI

struct SidebarRowButtonStyle: PrimitiveButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .onTapGesture { configuration.trigger() }
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { configuration.trigger() }
    }
}

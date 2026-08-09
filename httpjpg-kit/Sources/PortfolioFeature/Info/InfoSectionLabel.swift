import DesignSystem
import SwiftUI
import Tokens

struct InfoSectionLabel: View {
    private let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        MonoText(
            text,
            size: Typography.Size.xs,
            tracking: Typography.Size.xs * 0.2,
            opacity: Opacities.subtle
        )
        .textCase(.uppercase)
        .accessibilityAddTraits(.isHeader)
    }
}

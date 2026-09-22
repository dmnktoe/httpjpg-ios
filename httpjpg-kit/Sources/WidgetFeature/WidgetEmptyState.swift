import DesignSystem
import SwiftUI
import Tokens

struct WidgetEmptyState: View {
    let message: String?

    var body: some View {
        VStack(spacing: Spacing.s2) {
            AsciiArt(Ascii.ghost, label: "", size: Typography.Size.xxs, opacity: Opacities.dimmed)
            if let message, !message.isEmpty {
                Text(message)
                    .font(Typography.mono(Typography.Size.xxs))
                    .opacity(Opacities.subtle)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Spacing.s2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

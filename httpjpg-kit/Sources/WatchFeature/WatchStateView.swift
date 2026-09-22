import SwiftUI
import Tokens

struct WatchStateView: View {
    let art: String
    let message: String
    var retry: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.s2) {
            Text(art)
                .font(Typography.mono(Typography.Size.xxs))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: true, vertical: false)
                .opacity(Opacities.subtle)
                .accessibilityHidden(true)

            Text(message)
                .font(Typography.mono(Typography.Size.xs))
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .opacity(Opacities.muted)

            if let retry {
                Button("retry", action: retry)
                    .font(Typography.mono(Typography.Size.xs))
                    .foregroundStyle(Palette.accent.s400)
                    .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.s4)
    }
}

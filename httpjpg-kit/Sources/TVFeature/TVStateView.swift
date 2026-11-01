import SwiftUI
import Tokens

struct TVStateView: View {
    let art: String
    let message: String
    var retry: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.s6) {
            Text(art)
                .font(Typography.mono(TVMetrics.caption))
                .multilineTextAlignment(.center)
                .fixedSize()
                .opacity(Opacities.subtle)
                .accessibilityHidden(true)

            Text(message)
                .font(Typography.mono(TVMetrics.body))
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .opacity(Opacities.muted)
                .frame(maxWidth: TVMetrics.proseWidth)

            if let retry {
                Button("retry", action: retry)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

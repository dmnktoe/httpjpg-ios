import DesignSystem
import SwiftUI
import Tokens

struct FeedPostHeader: View {
    let name: String
    let avatarURL: URL?

    @Environment(\.pageTheme) private var theme

    private static let avatarSize: CGFloat = 28

    var body: some View {
        HStack(spacing: Spacing.s2) {
            avatar
                .frame(width: Self.avatarSize, height: Self.avatarSize)
                .clipShape(Circle())
                .accessibilityHidden(true)
            Text(name)
                .font(Typography.sansBold(Typography.Size.sm))
                .foregroundStyle(theme.foreground)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, PageLayout.gutter)
    }

    @ViewBuilder
    private var avatar: some View {
        if let avatarURL {
            RemoteImage(url: avatarURL, aspectRatio: 1, contentMode: .fill)
        } else {
            theme.foreground
                .overlay {
                    Text(String(name.prefix(1)).uppercased())
                        .font(Typography.mono(Typography.Size.xs))
                        .foregroundStyle(theme.background)
                }
        }
    }
}

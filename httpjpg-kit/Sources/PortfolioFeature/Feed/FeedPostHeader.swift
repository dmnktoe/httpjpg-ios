import DesignSystem
import SwiftUI
import Tokens

struct FeedPostHeader: View {
    let name: String
    let avatarURL: URL?

    @Environment(\.pageTheme) private var theme

    var body: some View {
        HStack(spacing: Spacing.s2) {
            FeedAvatar(name: name, url: avatarURL)
            Text(name)
                .font(Typography.sansBold(Typography.Size.sm))
                .foregroundStyle(theme.foreground)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, PageLayout.gutter)
    }
}

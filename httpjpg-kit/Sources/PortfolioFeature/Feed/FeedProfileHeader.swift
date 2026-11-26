import DesignSystem
import SwiftUI
import Tokens

struct FeedProfileHeader: View {
    let name: String?
    let avatarURL: URL?
    let postCount: String
    let ticker: [String]

    @Environment(\.pageTheme) private var theme

    private static let wordmarkSize: CGFloat = 72
    private static let avatarSize: CGFloat = 76

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s6) {
            wordmark
            if let name {
                profile(name: name)
            }
            if !ticker.isEmpty {
                VStack(spacing: 0) {
                    theme.border.frame(height: 1)
                    Marquee(ticker.map { "⋆ \($0) " }.joined(), speed: .rate(40))
                        .padding(.vertical, Spacing.s2)
                }
                .accessibilityHidden(true)
            }
        }
    }

    private var wordmark: some View {
        Text("httpGR\(Text("▲").foregroundStyle(Palette.primary.s500))M")
            .font(Typography.headline(Self.wordmarkSize))
            .tracking(Self.wordmarkSize * -0.06)
            .foregroundStyle(theme.foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(.horizontal, PageLayout.gutter)
            .accessibilityLabel("httpgram, the feed")
            .accessibilityAddTraits(.isHeader)
    }

    private func profile(name: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            HStack(spacing: Spacing.s4) {
                FeedAvatar(name: name, url: avatarURL, size: Self.avatarSize, ring: true)
                HStack(spacing: 0) {
                    stat(postCount, label: "posts")
                    stat("∞", label: "followers")
                    stat("0", label: "following")
                }
            }
            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(name)
                    .font(Typography.sansBold(Typography.Size.base))
                Text("photo dumps and music, newest first ⋆.˚")
                    .font(Typography.sans(Typography.Size.md))
            }
        }
        .foregroundStyle(theme.foreground)
        .padding(.horizontal, PageLayout.gutter)
    }

    private func stat(_ value: String, label: String) -> some View {
        VStack(spacing: Spacing.s1) {
            Text(value)
                .font(Typography.mono(Typography.Size.base, weight: .bold))
            Text(label)
                .font(Typography.mono(Typography.Size.xs))
                .foregroundStyle(theme.muted)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

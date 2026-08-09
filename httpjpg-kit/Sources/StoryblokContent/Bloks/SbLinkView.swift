import DesignSystem
import StoryblokCore
import SwiftUI

public struct SbLinkView: View {
    private let blok: LinkBlok

    @Environment(\.openURL) private var openURL
    @Environment(\.pageTheme) private var theme
    @Environment(\.storyblokConfiguration) private var configuration

    public init(blok: LinkBlok) {
        self.blok = blok
    }

    public var body: some View {
        if let url = resolvedURL {
            Button {
                openURL(url)
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.s1) {
                    Text(blok.text)
                        .font(Typography.sans(Typography.Size.base))
                        .underline()
                    if blok.showsExternalIcon {
                        MonoText("↗", size: Typography.Size.sm)
                    }
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .blokSpacing(blok.spacing)
        }
    }

    private var resolvedURL: URL? {
        guard let link = blok.link, !link.isEmpty else { return nil }
        return link.resolvedURL(siteOrigin: configuration.siteOrigin)
    }

    private var color: Color {
        Palette.named(blok.color) ?? theme.foreground
    }
}

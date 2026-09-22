import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

public struct SbButtonView: View {
    private let blok: ButtonBlok

    @Environment(\.openURL) private var openURL
    @Environment(\.storyblokConfiguration) private var configuration

    public init(blok: ButtonBlok) {
        self.blok = blok
    }

    public var body: some View {
        Button {
            guard let url = blok.link?.resolvedURL(siteOrigin: configuration.siteOrigin) else { return }
            openURL(url)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.s1) {
                Text(blok.text)
                // Web appends ↗ for absolute http(s)/mailto/tel hrefs.
                if blok.link?.isExternal == true {
                    Text("↗")
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.brutal(
            variant: BrutalButtonStyle.Variant(rawValue: blok.variant) ?? .primary,
            size: BrutalButtonStyle.Size(rawValue: blok.size) ?? .md
        ))
        .disabled(blok.isDisabled || blok.link?.isEmpty != false)
        .blokSpacing(blok.spacing)
    }
}

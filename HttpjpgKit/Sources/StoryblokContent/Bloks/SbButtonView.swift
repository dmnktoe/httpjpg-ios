import DesignSystem
import SwiftUI

public struct SbButtonView: View {
    private let blok: ButtonBlok

    @Environment(\.openURL) private var openURL
    @Environment(\.storyblokConfiguration) private var configuration

    public init(blok: ButtonBlok) {
        self.blok = blok
    }

    public var body: some View {
        Button(blok.text) {
            guard let url = blok.link?.resolvedURL(siteOrigin: configuration.siteOrigin) else { return }
            openURL(url)
        }
        .buttonStyle(.brutal(
            variant: BrutalButtonStyle.Variant(rawValue: blok.variant) ?? .primary,
            size: BrutalButtonStyle.Size(rawValue: blok.size) ?? .md
        ))
        .disabled(blok.isDisabled || blok.link?.isEmpty != false)
        .blokSpacing(blok.spacing)
    }
}

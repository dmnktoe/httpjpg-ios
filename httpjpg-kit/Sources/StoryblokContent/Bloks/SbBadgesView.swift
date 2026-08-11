import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

public struct SbBadgesView: View {
    private let blok: BadgesBlok

    @Environment(\.openURL) private var openURL

    public init(blok: BadgesBlok) {
        self.blok = blok
    }

    public var body: some View {
        if !blok.items.isEmpty {
            FlowLayout(spacing: Spacing.s2, alignment: rowAlignment) {
                ForEach(blok.items) { item in
                    badge(item)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .blokSpacing(blok.spacing)
        }
    }

    @ViewBuilder
    private func badge(_ item: BadgeItemBlok) -> some View {
        let image = BadgeImage(
            url: item.sourceURL,
            accessibilityText: item.alt.isEmpty ? (item.title ?? "") : item.alt,
            height: blok.height
        )
        if let url = item.linkURL {
            Button { openURL(url) } label: { image }
                .buttonStyle(.plain)
        } else {
            image
        }
    }

    private var rowAlignment: HorizontalAlignment {
        switch blok.justify {
        case "center": return .center
        case "end": return .trailing
        default: return .leading
        }
    }
}

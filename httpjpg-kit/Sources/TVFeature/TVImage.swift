import StoryblokCore
import SwiftUI
import Tokens

struct TVImage: View {
    let filename: String?

    let targetWidth: CGFloat

    @Environment(\.pageTheme) private var theme
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        AsyncImage(url: url, transaction: Transaction(animation: Motion.mediaIn)) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                theme.border.opacity(Opacities.dimmed)
            }
        }
        .accessibilityHidden(true)
    }

    private var url: URL? {
        guard let filename, !filename.isEmpty else { return nil }
        return URL(string: ImageService.Preset.width(filename, targetWidth, scale: displayScale))
    }
}

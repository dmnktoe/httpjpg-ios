import StoryblokCore
import SwiftUI
import Tokens

struct WatchThumbnail: View {
    let filename: String?

    let targetWidth: CGFloat

    var aspectRatio: CGFloat = 1

    @Environment(\.pageTheme) private var theme
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        Color.clear
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay { image }
            .clipped()
            .overlay {
                Rectangle().stroke(theme.border.opacity(Opacities.subtle), lineWidth: 1)
            }
            .accessibilityHidden(true)
    }

    private var image: some View {
        AsyncImage(url: url, transaction: Transaction(animation: Motion.mediaIn)) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                placeholder
            }
        }
    }

    private var placeholder: some View {
        theme.border.opacity(0.35)
            .overlay {
                Text(Ascii.tape)
                    .font(Typography.mono(7))
                    .opacity(Opacities.tape)
                    .lineLimit(1)
                    .fixedSize()
            }
    }

    private var url: URL? {
        guard let filename, !filename.isEmpty else { return nil }
        return URL(string: ImageService.Preset.width(filename, targetWidth, scale: displayScale))
    }
}

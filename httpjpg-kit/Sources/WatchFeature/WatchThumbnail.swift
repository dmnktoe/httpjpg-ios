import StoryblokCore
import SwiftUI
import Tokens

/// A hard-edged image box: no corner radius, a hairline frame, and the tape
/// motif holding the space until the bytes land. Same shape as the phone's
/// `RemoteImage` — a clear box carries the ratio so the row doesn't reflow
/// when the image decodes.
struct WatchThumbnail: View {
    let filename: String?

    /// Points of rendered width, so the CDN crop matches what the crown
    /// scrolls past instead of shipping a phone-sized frame over Bluetooth.
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

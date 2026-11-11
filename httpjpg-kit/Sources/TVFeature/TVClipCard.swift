import SwiftUI
import Tokens

// The picture half of a clip card: a poster where the feed has one, otherwise
// a plain plate, since a work's video carries no still of its own.
struct TVClipCard: View {
    let clip: TVClip

    @Environment(\.pageTheme) private var theme

    var body: some View {
        Color.clear
            .frame(width: TVMetrics.posterWidth, height: TVMetrics.posterWidth * 9 / 16)
            .overlay {
                if let poster = clip.poster {
                    TVImage(filename: poster, targetWidth: TVMetrics.posterWidth)
                } else {
                    theme.border.opacity(Opacities.dimmed)
                }
            }
            .overlay {
                Image(systemName: "play.fill")
                    .font(.system(size: TVMetrics.title))
                    .foregroundStyle(Palette.white)
                    .shadow(color: Palette.black.opacity(0.6), radius: 24)
                    .accessibilityHidden(true)
            }
            .clipped()
    }
}

import SwiftUI
import Tokens

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
                    .shadow(color: Palette.black.opacity(0.6), radius: Spacing.s6)
                    .accessibilityHidden(true)
            }
            .clipped()
    }
}

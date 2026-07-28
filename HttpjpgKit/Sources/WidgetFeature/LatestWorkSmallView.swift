import DesignSystem
import SwiftUI

/// The small square: the featured piece, full-bleed.
///
/// The image runs edge to edge with no inset — a widget is already a rounded
/// card on the home screen, so any further framing just shrinks the picture.
/// The title sits on a scrim at the bottom rather than beside the image,
/// because at 158pt there is no room for a column layout.
struct LatestWorkSmallView: View {
    let entry: LatestWorkEntry

    @Environment(\.pageTheme) private var theme

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            artwork
            caption
        }
    }

    @ViewBuilder
    private var artwork: some View {
        if let image = entry.image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            // No artwork is not an error state — plenty of entries are
            // text-only — so it gets the ASCII treatment rather than a glyph.
            theme.background
                .overlay {
                    AsciiArt(
                        Ascii.ghost,
                        label: "",
                        size: Typography.Size.sm,
                        opacity: Opacities.dimmed
                    )
                }
        }
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Ascii.tape)
                .font(Typography.mono(7))
                .opacity(0.7)
                .lineLimit(1)
            Text(entry.featured?.title ?? "nothing yet")
                .font(Typography.headline(15, relativeTo: .caption))
                .tracking(-0.4)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
        .padding(.top, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .bottom) { scrim }
    }

    /// A gradient, not a flat overlay: the ASCII strip and title need contrast
    /// against arbitrary photography without dimming the whole picture.
    private var scrim: some View {
        LinearGradient(
            colors: [.black.opacity(0), .black.opacity(0.75)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

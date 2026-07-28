import DesignSystem
import SwiftUI
import WidgetKit

/// The small square: the featured piece, full-bleed.
///
/// The image runs edge to edge with no inset — a widget is already a rounded
/// card on the home screen, so any further framing just shrinks the picture.
/// The title sits on a scrim at the bottom rather than beside the image,
/// because at 158pt there is no room for a column layout.
struct LatestWorkSmallView: View {
    let entry: LatestWorkEntry

    @Environment(\.pageTheme) private var theme
    /// Still populated when `contentMarginsDisabled()` is set — the system
    /// stops applying these, but it still says what they would have been, which
    /// is the number that keeps text clear of the rounded corners.
    @Environment(\.widgetContentMargins) private var systemMargins

    /// The artwork is the *background*, not a sibling in a `ZStack`. A
    /// `resizable().scaledToFill()` image reports a size larger than the one it
    /// was offered, so as a stack sibling it grew the stack wider than the
    /// widget and the caption laid out against that oversized width — which is
    /// why the title was clipped on both edges at once. As a background it can
    /// overflow all it likes; the caption sizes to the widget.
    var body: some View {
        caption
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .background { artwork }
            .clipped()
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
            // Laid out at its full length and clipped rather than truncated —
            // the tape is a strip of glyphs, and an ellipsis at the end of one
            // reads as a bug. `fixedSize` inside a bounded frame is what keeps
            // the overflow from widening the stack.
            Text(Ascii.tape)
                .font(Typography.mono(7))
                .opacity(0.7)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity, alignment: .leading)
                .clipped()
            Text(entry.featured?.title ?? "nothing yet")
                .font(Typography.headline(15, relativeTo: .caption))
                .tracking(-0.4)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.leading)
        }
        .foregroundStyle(.white)
        .padding(.leading, inset.leading)
        .padding(.trailing, inset.trailing)
        .padding(.bottom, inset.bottom)
        .padding(.top, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .bottom) { scrim }
    }

    /// The system's own margins, floored so the caption never sits in the
    /// corner radius even if the platform reports zero.
    private var inset: EdgeInsets {
        EdgeInsets(
            top: 0,
            leading: max(systemMargins.leading, 12),
            bottom: max(systemMargins.bottom, 10),
            trailing: max(systemMargins.trailing, 12)
        )
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

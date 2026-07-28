import DesignSystem
import StoryblokContent
import SwiftUI

/// The Apple-Music-style now-playing bar, in the site's voice.
///
/// A glass capsule that appears above the tab pills the moment a track starts
/// and stays across navigation. Tap or swipe up for the full-screen player;
/// the ✕ tears playback down entirely.
///
/// Fixed dark glass with white type, like the unselected tab pill — not the
/// page theme's colours. The bar floats over whatever is scrolling underneath,
/// and a theme-derived foreground turned black over dark imagery on light
/// pages. Chrome that cannot know its background picks colours that survive
/// any background.
struct MiniPlayerBar: View {
    let player: AudioPlayerModel
    /// The tab pill cluster's width, so the bar sits flush over the pills —
    /// growing with them when the preview pill joins. Zero (nothing measured
    /// yet) falls back to the page gutter.
    let width: CGFloat

    private static let tint = Palette.black.opacity(0.72)
    private static let labelColor = Palette.white.opacity(0.9)

    var body: some View {
        if let track = player.track {
            HStack(spacing: Spacing.s3) {
                artwork(track)
                // The title scrolls rather than truncates — same voice as the
                // rest of the site's strips.
                Marquee(
                    marqueeText(track),
                    font: Typography.uiMono(Typography.Size.xs),
                    speed: .rate(20),
                    color: Self.labelColor
                )
                .frame(maxWidth: .infinity)

                Button {
                    player.togglePlayPause()
                } label: {
                    Text(player.isPlaying ? "▮▮" : "▸")
                        .font(Typography.mono(Typography.Size.md, weight: .bold))
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                        // A fast glyph swap — anything slower makes the pause
                        // feel like it happened after the tap, not on it.
                        .contentTransition(.opacity)
                        .animation(.easeOut(duration: 0.1), value: player.isPlaying)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(player.isPlaying ? "Pause" : "Play")

                Button {
                    player.stop()
                } label: {
                    Text("✕")
                        .font(Typography.mono(Typography.Size.sm))
                        .opacity(Opacities.muted)
                        .frame(width: 28, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Stop playback")
            }
            .foregroundStyle(Self.labelColor)
            .padding(.horizontal, Spacing.s3)
            .padding(.vertical, Spacing.s2)
            .frame(width: width > 0 ? width : nil)
            .glassBackground(in: .capsule, tint: Self.tint)
            // Same clip as the other bordered glass: the material must stop
            // at the border, not bloom past it.
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Palette.neutral.s400.opacity(0.6), lineWidth: 1))
            .contentShape(Capsule())
            .onTapGesture { player.isExpanded = true }
            .gesture(
                DragGesture(minimumDistance: 15).onEnded { value in
                    if value.translation.height < -20 {
                        player.isExpanded = true
                    }
                }
            )
            .padding(.horizontal, width > 0 ? 0 : PageLayout.gutter)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Opens the full player")
        }
    }

    /// The cover comes from the model, which downloaded it once for the lock
    /// screen — not from a URL-loading view, which refetched (and flashed)
    /// every time the bar re-rendered.
    @ViewBuilder
    private func artwork(_ track: AudioTrack) -> some View {
        Group {
            if let image = player.artwork {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                MonoText("♫", size: Typography.Size.md)
            }
        }
        .frame(width: 32, height: 32)
        .clipped()
        .overlay(Rectangle().stroke(Palette.white.opacity(0.35), lineWidth: 1))
    }

    private func marqueeText(_ track: AudioTrack) -> String {
        let name = track.artist.map { "\(track.title) — \($0)" } ?? track.title
        return "\(name)  \(Ascii.dividerMusic)  "
    }
}

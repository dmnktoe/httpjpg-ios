import DesignSystem
import StoryblokContent
import SwiftUI

/// The Apple-Music-style now-playing bar, in the site's voice.
///
/// A glass capsule that appears above the tab pills the moment a track starts
/// and stays across navigation. Tap or swipe up for the full-screen player;
/// the ✕ tears playback down entirely.
struct MiniPlayerBar: View {
    let player: AudioPlayerModel

    @Environment(\.pageTheme) private var theme

    var body: some View {
        if let track = player.track {
            HStack(spacing: Spacing.s3) {
                artwork(track)
                // The title scrolls rather than truncates — same voice as the
                // rest of the site's strips.
                Marquee(
                    marqueeText(track),
                    font: Typography.uiMono(Typography.Size.xs),
                    speed: .rate(20)
                )
                .frame(maxWidth: .infinity)

                Button {
                    player.togglePlayPause()
                } label: {
                    Text(player.isPlaying ? "▮▮" : "▸")
                        .font(Typography.mono(Typography.Size.md, weight: .bold))
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
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
            .foregroundStyle(theme.foreground)
            .padding(.horizontal, Spacing.s3)
            .padding(.vertical, Spacing.s2)
            .glassBackground(in: .capsule)
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
            .padding(.horizontal, PageLayout.gutter)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Opens the full player")
        }
    }

    @ViewBuilder
    private func artwork(_ track: AudioTrack) -> some View {
        if let artworkURL = track.artworkURL {
            RemoteImage(url: artworkURL, aspectRatio: 1)
                .frame(width: 32, height: 32)
                .overlay(Rectangle().stroke(theme.border, lineWidth: 1))
        } else {
            MonoText("♫", size: Typography.Size.md)
                .frame(width: 32, height: 32)
                .overlay(Rectangle().stroke(theme.border, lineWidth: 1))
        }
    }

    private func marqueeText(_ track: AudioTrack) -> String {
        let name = track.artist.map { "\(track.title) — \($0)" } ?? track.title
        return "\(name)  \(Ascii.dividerMusic)  "
    }
}

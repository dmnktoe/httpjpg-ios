import DesignSystem
import StoryblokContent
import SwiftUI

struct MiniPlayerBar: View {
    let player: AudioPlayerModel

    let width: CGFloat

    private static let tint = Palette.black.opacity(0.72)
    private static let labelColor = Palette.white.opacity(0.9)

    private static let rowHeight: CGFloat = 32

    /// What the bar takes off the bottom of the screen once a track is on.
    static let height: CGFloat = rowHeight + Spacing.s2 * 2

    @State private var playPauseTaps = 0

    var body: some View {
        if let track = player.track {
            HStack(spacing: Spacing.s3) {
                artwork(track)

                Marquee(
                    marqueeText(track),
                    font: Typography.uiMono(Typography.Size.xs),
                    speed: .rate(20),
                    color: Self.labelColor
                )
                .frame(maxWidth: .infinity)

                Button {
                    playPauseTaps += 1
                    player.togglePlayPause()
                } label: {
                    Text(player.isPlaying ? "▮▮" : "▸")
                        .font(Typography.mono(Typography.Size.md, weight: .bold))
                        .frame(width: Self.rowHeight, height: Self.rowHeight)
                        .contentShape(Rectangle())

                        .contentTransition(.opacity)
                        .animation(.easeOut(duration: 0.1), value: player.isPlaying)
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.impact(weight: .light), trigger: playPauseTaps)
                .accessibilityLabel(player.isPlaying ? "Pause" : "Play")

                Button {
                    player.stop()
                } label: {
                    Text("✕")
                        .font(Typography.mono(Typography.Size.sm))
                        .opacity(Opacities.muted)
                        .frame(width: 28, height: Self.rowHeight)
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
        .frame(width: Self.rowHeight, height: Self.rowHeight)
        .clipped()
        .overlay(Rectangle().stroke(Palette.white.opacity(0.35), lineWidth: 1))
    }

    private func marqueeText(_ track: AudioTrack) -> String {
        let name = track.artist.map { "\(track.title) — \($0)" } ?? track.title
        return "\(name)  \(Ascii.dividerMusic)  "
    }
}

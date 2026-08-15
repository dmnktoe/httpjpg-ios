import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

struct MiniPlayerBar: View {
    let player: AudioPlayerModel

    let width: CGFloat

    let glass: Namespace.ID

    private static let rowHeight: CGFloat = 32

    static let height: CGFloat = rowHeight + Spacing.s2 * 2

    @Environment(\.pageTheme) private var theme
    @Environment(\.chromeAccent) private var accent
    @Environment(\.chromeOnAccent) private var onAccent
    @State private var playPauseTaps = 0

    var body: some View {
        if let track = player.track {
            HStack(spacing: Spacing.s3) {
                artwork(track)

                Marquee(
                    marqueeText(track),
                    font: Typography.uiMono(Typography.Size.xs),
                    speed: .rate(20),
                    color: theme.chromeLabel(onAccent: onAccent)
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
                        .animation(Motion.pressed, value: player.isPlaying)
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
            .foregroundStyle(theme.chromeLabel(onAccent: onAccent))
            .padding(.horizontal, Spacing.s3)
            .padding(.vertical, Spacing.s2)
            .frame(width: width > 0 ? width : nil)
            .glassBackground(in: .capsule, tint: theme.chromeFill(accent: accent))
            .glassMorph(id: "player", in: glass)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(theme.chromeStroke(accent: accent), lineWidth: 1))
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
            .glassReveal()
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
        .overlay(Rectangle().stroke(theme.chromeStroke(accent: accent), lineWidth: 1))
    }

    private func marqueeText(_ track: AudioTrack) -> String {
        let name = track.artist.map { "\(track.title) — \($0)" } ?? track.title
        return "\(name)  \(Ascii.dividerMusic)  "
    }
}

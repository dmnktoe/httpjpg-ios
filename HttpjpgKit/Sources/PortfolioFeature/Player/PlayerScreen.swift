import DesignSystem
import StoryblokContent
import SwiftUI

struct PlayerScreen: View {
    let player: AudioPlayerModel

    @Environment(\.colorScheme) private var systemScheme

    @State private var playPauseTaps = 0

    var body: some View {
        let theme: PageTheme = systemScheme == .dark ? .dark : .light
        VStack(spacing: Spacing.s6) {
            MonoText(Ascii.dividerMusic, size: Typography.Size.sm, opacity: Opacities.muted)
                .padding(.top, Spacing.s8)

            if let track = player.track {
                artwork(track, theme: theme)

                VStack(spacing: Spacing.s2) {
                    Headline(track.title, level: .three, alignment: .center)
                        .lineLimit(3)
                    if let artist = track.artist {
                        MonoText(artist, size: Typography.Size.sm, opacity: Opacities.muted)
                    }
                }
                .padding(.horizontal, PageLayout.gutter)

                scrubber(theme: theme)
                transport

                AirPlayPicker(tint: theme.foreground)
                    .frame(width: 44, height: 44)
                    .accessibilityLabel("AirPlay")
            }

            Spacer(minLength: 0)

            MonoText(Ascii.tape, size: Typography.Size.xxs, opacity: Opacities.tape)
                .lineLimit(1)
                .padding(.bottom, Spacing.s6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .pageTheme(theme)
        .pageSurface(theme)
        .presentationDragIndicator(.visible)
    }

    private func artwork(_ track: AudioTrack, theme: PageTheme) -> some View {
        Group {
            if let image = player.artwork {
                Color.clear
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
            } else {
                MonoText(Ascii.dividerMusic, size: Typography.Size.lg, opacity: Opacities.dimmed)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
            }
        }
        .overlay(Rectangle().stroke(theme.border, lineWidth: 1))
        .padding(.horizontal, Spacing.s10)
    }

    private func scrubber(theme: PageTheme) -> some View {
        VStack(spacing: Spacing.s1) {
            Slider(
                value: Binding(
                    get: { player.currentTime },
                    set: { player.seek(to: $0) }
                ),
                in: 0 ... max(player.duration, 1)
            )
            .tint(theme.foreground)

            HStack {
                MonoText(timestamp(player.currentTime), size: Typography.Size.xxs, opacity: Opacities.muted)
                Spacer(minLength: 0)
                MonoText(timestamp(player.duration), size: Typography.Size.xxs, opacity: Opacities.muted)
            }
        }
        .padding(.horizontal, PageLayout.gutter)
    }

    private var transport: some View {
        HStack(spacing: Spacing.s8) {
            skipButton(by: -15, label: "↺15", accessibility: "Back 15 seconds")
            Button {
                playPauseTaps += 1
                player.togglePlayPause()
            } label: {
                Text(player.isPlaying ? "▮▮" : "▸")
                    .font(Typography.mono(28, weight: .bold))
                    .frame(width: 64, height: 64)
                    .contentShape(Rectangle())

                    .contentTransition(.opacity)
                    .animation(.easeOut(duration: 0.1), value: player.isPlaying)
            }
            .buttonStyle(.plain)

            .sensoryFeedback(.impact(weight: .light), trigger: playPauseTaps)
            .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
            skipButton(by: 15, label: "↻15", accessibility: "Forward 15 seconds")
        }
    }

    private func skipButton(by seconds: TimeInterval, label: String, accessibility: String) -> some View {
        Button {
            player.seek(to: player.currentTime + seconds)
        } label: {
            Text(label)
                .font(Typography.mono(Typography.Size.md))
                .opacity(Opacities.muted)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibility)
    }

    private func timestamp(_ value: TimeInterval) -> String {
        guard value.isFinite, value > 0 else { return "0:00" }
        let total = Int(value.rounded(.down))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

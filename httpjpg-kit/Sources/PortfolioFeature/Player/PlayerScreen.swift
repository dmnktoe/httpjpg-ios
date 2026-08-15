import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

struct PlayerScreen: View {
    let player: AudioPlayerModel
    let glass: Namespace.ID

    @Environment(\.pageTheme) private var theme
    @Environment(\.chromeAccent) private var accent
    @Environment(\.chromeOnAccent) private var onAccent
    @Environment(\.dismiss) private var dismiss

    @State private var playPauseTaps = 0

    var body: some View {
        VStack(spacing: Spacing.s6) {
            chromeHandle

            MonoText(Ascii.dividerMusic, size: Typography.Size.sm, opacity: Opacities.muted)

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

                scrubber
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
        .presentationDragIndicator(.hidden)
    }

    private var chromeHandle: some View {
        HStack(spacing: Spacing.s3) {
            Text(Ascii.sparkles)
                .font(Typography.mono(Typography.Size.xxs))
                .opacity(Opacities.subtle)
                .lineLimit(1)
                .minimumScaleFactor(0.3)

            Spacer(minLength: 0)

            Button {
                dismiss()
            } label: {
                Text("✕")
                    .font(Typography.mono(Typography.Size.sm))
                    .frame(width: Spacing.s9, height: Spacing.s9)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close player")
        }
        .foregroundStyle(theme.chromeLabel(onAccent: onAccent))
        .padding(.horizontal, Spacing.s4)
        .padding(.vertical, Spacing.s2)
        .glassBackground(in: .capsule, tint: theme.chromeFill(accent: accent))
        .glassMorph(id: "player", in: glass)
        .overlay(Capsule().stroke(theme.chromeStroke(accent: accent), lineWidth: 1))
        .padding(.horizontal, PageLayout.gutter)
        .padding(.top, Spacing.s4)
        .glassReveal()
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

    private var scrubber: some View {
        VStack(spacing: Spacing.s1) {
            GlassScrubber(
                value: Binding(
                    get: { player.currentTime },
                    set: { player.seek(to: $0) }
                ),
                in: 0 ... max(player.duration, 1),
                tint: accent ?? theme.foreground
            )

            HStack {
                MonoText(timestamp(player.currentTime), size: Typography.Size.xxs, opacity: Opacities.muted)
                Spacer(minLength: 0)
                MonoText(timestamp(player.duration), size: Typography.Size.xxs, opacity: Opacities.muted)
            }
        }
        .padding(.horizontal, PageLayout.gutter)
    }

    private var transport: some View {
        GlassGroup {
            HStack(spacing: Spacing.s8) {
                skipButton(by: -15, label: "↺15", accessibility: "Back 15 seconds")
                Button {
                    playPauseTaps += 1
                    player.togglePlayPause()
                } label: {
                    Text(player.isPlaying ? "▮▮" : "▸")
                        .font(Typography.mono(28, weight: .bold))
                        .foregroundStyle(theme.chromeLabel(onAccent: onAccent))
                        .frame(width: 64, height: 64)
                        .contentShape(Circle())
                        .contentTransition(.opacity)
                        .animation(Motion.pressed, value: player.isPlaying)
                        .glassBackground(in: .circle, tint: theme.chromeFill(accent: accent), interactive: true)
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.impact(weight: .light), trigger: playPauseTaps)
                .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
                skipButton(by: 15, label: "↻15", accessibility: "Forward 15 seconds")
            }
        }
    }

    private func skipButton(by seconds: TimeInterval, label: String, accessibility: String) -> some View {
        Button {
            player.seek(to: player.currentTime + seconds)
        } label: {
            Text(label)
                .font(Typography.mono(Typography.Size.md))
                .foregroundStyle(theme.chromeLabel(onAccent: onAccent))
                .opacity(Opacities.muted)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
                .glassBackground(in: .circle, tint: theme.chromeFill(accent: accent), interactive: true)
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

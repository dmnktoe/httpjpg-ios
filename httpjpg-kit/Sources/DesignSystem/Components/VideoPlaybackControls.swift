import AVFoundation
import SwiftUI
import Tokens

/// Full-bleed overlay matching web `VideoControls` (PR #448): tap the picture
/// to play/pause when controls are on; keep chrome visible while paused so
/// Play stays discoverable on touch.
struct VideoPlaybackControls: View {
    let player: AVPlayer
    let showsControls: Bool

    @State private var isPlaying = false

    var body: some View {
        if showsControls {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(perform: togglePlay)
                .overlay(alignment: .bottom) {
                    if !isPlaying {
                        chrome
                            .transition(.opacity)
                    }
                }
                .onAppear { syncFromPlayer() }
                .onReceive(player.publisher(for: \.timeControlStatus)) { status in
                    isPlaying = status == .playing
                }
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel(isPlaying ? "Pause" : "Play")
                .accessibilityAction { togglePlay() }
        }
    }

    private var chrome: some View {
        HStack(spacing: Spacing.s3) {
            Image(systemName: "play.fill")
                .font(.system(size: Typography.Size.md, weight: .semibold))
                .foregroundStyle(Palette.white)
                .frame(width: Spacing.s8, height: Spacing.s8)
                .accessibilityHidden(true)

            MonoText("play", size: Typography.Size.sm)
                .foregroundStyle(Palette.white)

            Spacer(minLength: 0)
        }
        .padding(Spacing.s4)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Palette.black.opacity(0.9), Palette.black.opacity(0)],
                startPoint: .bottom,
                endPoint: .top
            )
        )
        .allowsHitTesting(false)
    }

    private func syncFromPlayer() {
        isPlaying = player.timeControlStatus == .playing
    }

    private func togglePlay() {
        if player.timeControlStatus == .playing {
            player.pause()
        } else {
            MediaAudioSession.prepareSilentVideo()
            player.play()
        }
    }
}

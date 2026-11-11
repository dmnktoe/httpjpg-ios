import StoryblokCore
import SwiftUI
import Tokens

struct TVPlayerScreen: View {
    let frames: [TVGalleryFrame]
    let loop: URL?

    @State private var player: TVAudioPlayer

    private static let artworkWidth: CGFloat = 240
    private static let progressWidth: CGFloat = 640

    init(tracks: [AudioTrack], start: AudioTrack, frames: [TVGalleryFrame], loop: URL?) {
        self.frames = frames
        self.loop = loop
        _player = State(initialValue: TVAudioPlayer(tracks: tracks, start: start))
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            backdrop

            LinearGradient(
                colors: [Palette.black.opacity(0.9), Palette.black.opacity(0.35)],
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )
            .ignoresSafeArea()

            if let track = player.track {
                nowPlaying(track)
            }
        }
        .foregroundStyle(Palette.white)
        .onAppear { player.start() }
        .onDisappear { player.stop() }
        .keepsScreenAwake(player.isPlaying)
        .tvPlayPause { player.togglePlayPause() }
    }

    // Something that moves behind the music: a silent clip from the feed where
    // there is one, otherwise the gallery's slow loop.
    @ViewBuilder
    private var backdrop: some View {
        if let loop {
            TVLoopingVideo(url: loop)
                .ignoresSafeArea()
                .accessibilityHidden(true)
        } else if !frames.isEmpty {
            TVSlideshowView(frames: frames, showsCaption: false)
                .accessibilityHidden(true)
        } else {
            Palette.black.ignoresSafeArea()
        }
    }

    private func nowPlaying(_ track: AudioTrack) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            if track.artworkURL != nil {
                Color.clear
                    .frame(width: Self.artworkWidth, height: Self.artworkWidth)
                    .overlay {
                        TVImage(filename: track.artworkURL?.absoluteString, targetWidth: Self.artworkWidth)
                    }
                    .clipped()
                    .padding(.bottom, Spacing.s4)
            }

            Text(Ascii.dividerMusic)
                .font(Typography.mono(TVMetrics.label))
                .opacity(Opacities.subtle)
                .accessibilityHidden(true)

            Text(track.title)
                .font(Typography.headline(TVMetrics.display))
                .tracking(Typography.Tracking.tight(TVMetrics.display))
                .lineLimit(2)
                .minimumScaleFactor(0.6)

            if let artist = track.artist {
                Text(artist)
                    .font(Typography.mono(TVMetrics.body))
                    .opacity(Opacities.muted)
            }

            ProgressView(value: player.progress)
                .tint(Palette.white)
                .frame(width: Self.progressWidth)
                .padding(.top, Spacing.s4)
                .accessibilityLabel("progress")

            controls
                .padding(.top, Spacing.s4)
        }
        .padding(TVMetrics.overscanInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }

    private var controls: some View {
        HStack(spacing: Spacing.s6) {
            if player.hasSeveralTracks {
                Button {
                    player.skip(-1)
                } label: {
                    Image(systemName: "backward.fill")
                }
                .accessibilityLabel("previous track")
            }

            Button {
                player.togglePlayPause()
            } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
            }
            .accessibilityLabel(player.isPlaying ? "pause" : "play")

            if player.hasSeveralTracks {
                Button {
                    player.skip(1)
                } label: {
                    Image(systemName: "forward.fill")
                }
                .accessibilityLabel("next track")
            }
        }
    }
}

import DesignSystem
import SwiftUI

/// Renders the `music_player` blok — the inline card, not the player.
///
/// Playback is app state: tapping play hands an ``AudioTrack`` to whatever the
/// app registered under `\.playAudioTrack`, and the mini bar takes it from
/// there. The card itself mirrors the web's mp3 player frame — decoration line,
/// header text, artwork beside title and artist, footer text — minus the inline
/// transport, which the bar and the full-screen player own on iOS.
///
/// Spotify and SoundCloud sources hand off to the browser, same reasoning as
/// `SbVideoView`: no raw stream, and embedding their web player would drag its
/// tracking into the app.
public struct SbMusicPlayerView: View {
    private let blok: MusicPlayerBlok

    @Environment(\.playAudioTrack) private var playAudioTrack
    @Environment(\.openURL) private var openURL
    @Environment(\.pageTheme) private var theme

    public init(blok: MusicPlayerBlok) {
        self.blok = blok
    }

    public var body: some View {
        if blok.sourceURL != nil {
            VStack(spacing: Spacing.s3) {
                MonoText(blok.decoration, size: Typography.Size.xs, opacity: Opacities.muted)
                if let headerText = blok.headerText {
                    MonoText(headerText, size: Typography.Size.sm)
                }

                if let track = blok.track {
                    trackRow(track)
                } else if let url = blok.externalURL {
                    handoff(url)
                }

                if let footerText = blok.footerText {
                    MonoText(footerText, size: Typography.Size.sm)
                }
                MonoText(blok.decoration, size: Typography.Size.xs, opacity: Opacities.muted)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.s4)
            .overlay(Rectangle().stroke(theme.border, lineWidth: 1))
            .blokSpacing(blok.spacing)
        }
    }

    private func trackRow(_ track: AudioTrack) -> some View {
        HStack(spacing: Spacing.s3) {
            if blok.showsArtwork, let artworkURL = track.artworkURL {
                RemoteImage(url: artworkURL, aspectRatio: 1)
                    .frame(width: 48, height: 48)
                    .overlay(Rectangle().stroke(theme.border, lineWidth: 1))
            }
            if blok.showsInfo {
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(Typography.sansBold(Typography.Size.sm))
                        .lineLimit(1)
                    if let artist = track.artist {
                        MonoText(artist, size: Typography.Size.xs, opacity: Opacities.muted)
                    }
                }
            }
            Spacer(minLength: Spacing.s2)
            Button {
                playAudioTrack(track)
            } label: {
                Text("▸ PLAY")
                    .font(Typography.mono(Typography.Size.sm, weight: .bold))
                    .padding(.horizontal, Spacing.s3)
                    .padding(.vertical, Spacing.s2)
                    .overlay(Rectangle().stroke(theme.foreground, lineWidth: 1))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Play \(track.title)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func handoff(_ url: URL) -> some View {
        Button {
            openURL(url)
        } label: {
            MonoText("▸ listen on \(url.host ?? blok.source)", size: Typography.Size.sm)
                .padding(.vertical, Spacing.s2)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

import StoryblokCore
import SwiftUI
import Tokens

struct TVFeedScreen: View {
    @Environment(TVAppModel.self) private var model

    @State private var playing: AudioTrack?
    @State private var clip: TVClip?

    private static let artworkWidth: CGFloat = 300

    var body: some View {
        content
            .fullScreenCover(item: $playing) { track in
                TVPlayerScreen(
                    tracks: model.tracks,
                    start: track,
                    frames: model.galleryFrames,
                    loop: model.clips.first?.url
                )
            }
            .fullScreenCover(item: $clip) { clip in
                TVVideoScreen(url: clip.url)
            }
    }

    @ViewBuilder
    private var content: some View {
        if model.tracks.isEmpty, model.clips.isEmpty {
            TVStateView(
                art: Ascii.ghost,
                message: model.isFeedLoaded ? "nothing to play yet" : "loading…"
            )
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: TVMetrics.sectionGap) {
                    header
                    if !model.tracks.isEmpty {
                        row("listen") {
                            ForEach(model.tracks) { track in
                                trackCard(track)
                            }
                        }
                    }
                    if !model.clips.isEmpty {
                        row("watch") {
                            ForEach(model.clips) { clip in
                                clipCard(clip)
                            }
                        }
                    }
                }
                .padding(.bottom, TVMetrics.sectionGap)
            }
            .scrollClipDisabled()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(Ascii.dividerMusic)
                .font(Typography.mono(TVMetrics.label))
                .opacity(Opacities.subtle)
                .accessibilityHidden(true)

            Text("feed")
                .font(Typography.headline(TVMetrics.display))
                .tracking(Typography.Tracking.tight(TVMetrics.display))

            Text("\(model.tracks.count) tracks, \(model.clips.count) clips")
                .font(Typography.mono(TVMetrics.caption))
                .opacity(Opacities.muted)
        }
    }

    private func row<Cards: View>(_ title: String, @ViewBuilder cards: () -> Cards) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text(title)
                .font(Typography.mono(TVMetrics.caption))
                .opacity(Opacities.muted)
                .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: TVMetrics.cardGap) {
                    cards()
                }
                .padding(.vertical, Spacing.s8)
            }
            .scrollClipDisabled()
        }
        .tvFocusSection()
    }

    // Only the picture is the button, as on the work wall, so the focus lift
    // moves the artwork and leaves its caption in place.
    private func trackCard(_ track: AudioTrack) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Button {
                playing = track
            } label: {
                Color.clear
                    .frame(width: Self.artworkWidth, height: Self.artworkWidth)
                    .overlay {
                        TVImage(filename: track.artworkURL?.absoluteString, targetWidth: Self.artworkWidth)
                    }
                    .clipped()
            }
            .tvCardStyle()
            .accessibilityLabel([track.title, track.artist].compactMap { $0 }.joined(separator: ", "))

            caption(track.title, detail: track.artist)
                .frame(width: Self.artworkWidth, alignment: .leading)
        }
    }

    private func clipCard(_ clip: TVClip) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Button {
                self.clip = clip
            } label: {
                TVClipCard(clip: clip)
            }
            .tvCardStyle()
            .accessibilityLabel(clip.caption ?? "clip")

            if let caption = clip.caption {
                self.caption(caption, detail: nil)
                    .frame(width: TVMetrics.posterWidth, alignment: .leading)
            }
        }
    }

    private func caption(_ title: String, detail: String?) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            Text(title)
                .font(Typography.sansBold(TVMetrics.caption))
                .lineLimit(1)
            if let detail {
                Text(detail)
                    .font(Typography.mono(TVMetrics.label))
                    .opacity(Opacities.subtle)
                    .lineLimit(1)
            }
        }
        .accessibilityHidden(true)
    }
}

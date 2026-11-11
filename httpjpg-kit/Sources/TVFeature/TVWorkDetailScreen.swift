import StoryblokCore
import SwiftUI
import Tokens

struct TVWorkDetailScreen: View {
    let item: WorkItem

    @State private var slideshow: TVSlideshowStart?
    @State private var clip: TVClip?

    private var frames: [TVGalleryFrame] {
        TVGalleryFrame.frames(of: item)
    }

    private var clips: [TVClip] {
        TVClip.clips(of: item)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TVMetrics.sectionGap) {
                intro
                if frames.count > 1 {
                    stills
                }
                if !clips.isEmpty {
                    videos
                }
            }
            // Without rows the intro is exactly one screen and must not scroll.
            .padding(.bottom, frames.count > 1 || !clips.isEmpty ? TVMetrics.sectionGap : 0)
        }
        .scrollClipDisabled()
        .background { backdrop }
        .fullScreenCover(item: $slideshow) { start in
            TVSlideshowView(frames: frames, startIndex: start.index, isStarted: true)
        }
        .fullScreenCover(item: $clip) { clip in
            TVVideoScreen(url: clip.url)
        }
    }

    private var backdrop: some View {
        Color.clear
            .overlay {
                TVImage(filename: frames.first?.filename, targetWidth: TVMetrics.screenWidth)
            }
            .clipped()
            .overlay {
                LinearGradient(
                    colors: [
                        Palette.black.opacity(0.92),
                        Palette.black.opacity(0.6),
                        Palette.black.opacity(0.15),
                    ],
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                )
            }
            .ignoresSafeArea()
    }

    // One screen tall, so the frames row starts below the fold and the
    // backdrop gets the whole first view.
    private var intro: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Spacer(minLength: 0)

            Text(Ascii.tape)
                .font(Typography.mono(TVMetrics.label))
                .opacity(Opacities.tape)
                .accessibilityHidden(true)

            Text(item.title)
                .font(Typography.headline(TVMetrics.display))
                .tracking(Typography.Tracking.tight(TVMetrics.display))
                .lineLimit(2)
                .minimumScaleFactor(0.6)

            if let date = item.date {
                Text(WorkCardDate.stamp(of: date))
                    .font(Typography.mono(TVMetrics.caption))
                    .opacity(Opacities.muted)
            }

            if !item.summary.isEmpty {
                Text(item.summary)
                    .font(Typography.sans(TVMetrics.body))
                    .lineSpacing(TVMetrics.body * 0.3)
                    .lineLimit(5)
                    .frame(maxWidth: TVMetrics.proseWidth, alignment: .leading)
            }

            if !tags.isEmpty {
                Text(tags)
                    .font(Typography.mono(TVMetrics.label))
                    .opacity(Opacities.muted)
            }

            HStack(spacing: Spacing.s6) {
                if !frames.isEmpty {
                    Button {
                        slideshow = TVSlideshowStart(index: 0)
                    } label: {
                        Label("gallery", systemImage: "play.fill")
                    }
                }
                // A work that is only a film still needs a way in from the first screen.
                if frames.isEmpty, let first = clips.first {
                    Button {
                        clip = first
                    } label: {
                        Label("play", systemImage: "play.fill")
                    }
                }
            }
            .padding(.top, Spacing.s4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerRelativeFrame(.vertical, alignment: .bottomLeading)
    }

    private var stills: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text("frames")
                .font(Typography.mono(TVMetrics.caption))
                .opacity(Opacities.muted)

            ScrollView(.horizontal) {
                LazyHStack(spacing: TVMetrics.cardGap) {
                    ForEach(Array(frames.enumerated()), id: \.element.id) { index, frame in
                        Button {
                            slideshow = TVSlideshowStart(index: index)
                        } label: {
                            Color.clear
                                .frame(width: TVMetrics.posterWidth, height: TVMetrics.posterWidth * 9 / 16)
                                .overlay {
                                    TVImage(filename: frame.filename, targetWidth: TVMetrics.posterWidth)
                                }
                                .clipped()
                        }
                        .tvCardStyle()
                        .accessibilityLabel("frame \(index + 1) of \(frames.count)")
                    }
                }
                .padding(.vertical, Spacing.s8)
            }
            .scrollClipDisabled()
        }
        .tvFocusSection()
    }

    private var videos: some View {
        VStack(alignment: .leading, spacing: Spacing.s4) {
            Text("clips")
                .font(Typography.mono(TVMetrics.caption))
                .opacity(Opacities.muted)

            ScrollView(.horizontal) {
                LazyHStack(spacing: TVMetrics.cardGap) {
                    ForEach(Array(clips.enumerated()), id: \.element.id) { index, clip in
                        Button {
                            self.clip = clip
                        } label: {
                            TVClipCard(clip: clip)
                        }
                        .tvCardStyle()
                        .accessibilityLabel("clip \(index + 1) of \(clips.count)")
                    }
                }
                .padding(.vertical, Spacing.s8)
            }
            .scrollClipDisabled()
        }
        .tvFocusSection()
    }

    private var tags: String {
        item.tags.map { "#" + $0 }.joined(separator: " ")
    }
}

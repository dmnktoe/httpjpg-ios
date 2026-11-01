import StoryblokCore
import SwiftUI
import Tokens

struct TVWorkDetailScreen: View {
    let item: WorkItem

    @State private var slideshow: TVSlideshowStart?

    private var frames: [TVGalleryFrame] {
        TVGalleryFrame.frames(of: item)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TVMetrics.sectionGap) {
                intro
                if frames.count > 1 {
                    stills
                }
            }
        }
        .scrollClipDisabled()
        .background { backdrop }
        .fullScreenCover(item: $slideshow) { start in
            TVSlideshowView(frames: frames, startIndex: start.index, keepsAwake: true)
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

            if !frames.isEmpty {
                Button {
                    slideshow = TVSlideshowStart(index: 0)
                } label: {
                    Label("gallery", systemImage: "play.fill")
                }
                .padding(.top, Spacing.s4)
            }
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
        .padding(.bottom, TVMetrics.sectionGap)
    }

    private var tags: String {
        item.tags.map { "#" + $0 }.joined(separator: " ")
    }
}

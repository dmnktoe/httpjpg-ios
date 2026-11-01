import StoryblokCore
import SwiftUI
import Tokens

struct TVSlideshowView: View {
    let frames: [TVGalleryFrame]
    var showsCaption = true
    var keepsAwake = false

    @State private var index: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let interval: TimeInterval = 9
    private static let crossfade: Animation = .easeInOut(duration: 1.6)

    init(frames: [TVGalleryFrame], startIndex: Int = 0, showsCaption: Bool = true, keepsAwake: Bool = false) {
        self.frames = frames
        self.showsCaption = showsCaption
        self.keepsAwake = keepsAwake
        _index = State(initialValue: frames.indices.contains(startIndex) ? startIndex : 0)
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Palette.black

            if let frame = current {
                // Keyed by position too, so a one-frame loop still restarts its drift.
                TVKenBurnsFrame(
                    filename: frame.filename,
                    drift: index.isMultiple(of: 2) ? .towardsTopLeading : .towardsBottomTrailing,
                    duration: Self.interval + 2,
                    isStill: reduceMotion
                )
                .id("\(index)|\(frame.id)")
                .transition(.opacity)

                if showsCaption {
                    caption(frame)
                        .id(frame.item.id)
                        .transition(.opacity)
                }
            }

            if let next {
                // Loaded off-screen so the crossfade lands on a finished image.
                TVImage(filename: next.filename, targetWidth: TVMetrics.screenWidth)
                    .frame(width: 1, height: 1)
                    .opacity(0)
            }
        }
        .ignoresSafeArea()
        .keepsScreenAwake(keepsAwake)
        .task(id: frames) { await cycle() }
    }

    private func caption(_ frame: TVGalleryFrame) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            Text(Ascii.tape)
                .font(Typography.mono(TVMetrics.label))
                .opacity(Opacities.tape)
                .accessibilityHidden(true)
            Text(frame.item.title)
                .font(Typography.headline(TVMetrics.title))
            if let date = frame.item.date {
                Text(WorkCardDate.year(of: date))
                    .font(Typography.mono(TVMetrics.caption))
                    .opacity(Opacities.muted)
            }
        }
        .foregroundStyle(Palette.white)
        .shadow(color: Palette.black.opacity(0.6), radius: 24)
        .padding(TVMetrics.overscanInset)
    }

    private var current: TVGalleryFrame? {
        frames.indices.contains(index) ? frames[index] : frames.first
    }

    private var next: TVGalleryFrame? {
        guard frames.count > 1 else { return nil }
        return frames[(index + 1) % frames.count]
    }

    private func cycle() async {
        guard frames.count > 1 else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(Self.interval))
            guard !Task.isCancelled else { return }
            withAnimation(Self.crossfade) {
                index = (index + 1) % frames.count
            }
        }
    }
}

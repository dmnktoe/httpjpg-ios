import SwiftUI
import Tokens

struct TVSlideshowView: View {
    let frames: [TVGalleryFrame]
    var showsCaption = true
    var isStarted = false
    var status: [TVStatusLine] = []

    @State private var index: Int
    @State private var isPaused = false
    @State private var steps = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let interval: TimeInterval = 9
    private static let crossfade: Animation = .easeInOut(duration: 1.6)

    private struct Cycle: Equatable {
        let frames: [TVGalleryFrame]
        let isPaused: Bool
        let steps: Int
    }

    init(
        frames: [TVGalleryFrame],
        startIndex: Int = 0,
        showsCaption: Bool = true,
        isStarted: Bool = false,
        status: [TVStatusLine] = []
    ) {
        self.frames = frames
        self.showsCaption = showsCaption
        self.isStarted = isStarted
        self.status = status
        _index = State(initialValue: frames.indices.contains(startIndex) ? startIndex : 0)
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Palette.black

            if let frame = current {
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
                TVImage(filename: next.filename, targetWidth: TVMetrics.screenWidth)
                    .frame(width: 1, height: 1)
                    .opacity(0)
            }
        }
        .overlay(alignment: .bottomTrailing) { ticker }
        .overlay(alignment: .topTrailing) { pauseMark }
        .ignoresSafeArea()
        .keepsScreenAwake(isStarted && !isPaused)
        .tvSlideshowRemote(isEnabled: isStarted, onStep: step) {
            isPaused.toggle()
        }
        .task(id: Cycle(frames: frames, isPaused: isPaused, steps: steps)) { await cycle() }
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
        .shadow(color: Palette.black.opacity(0.6), radius: Spacing.s6)
        .padding(TVMetrics.overscanInset)
    }

    @ViewBuilder
    private var ticker: some View {
        if isStarted, !status.isEmpty {
            let line = status[index % status.count]
            Text(line.text)
                .font(Typography.mono(TVMetrics.label))
                .lineLimit(1)
                .foregroundStyle(Palette.white)
                .opacity(Opacities.muted)
                .shadow(color: Palette.black.opacity(0.6), radius: Spacing.s6)
                .frame(maxWidth: TVMetrics.screenWidth / 2, alignment: .trailing)
                .padding(TVMetrics.overscanInset)
                .id(line.id)
                .transition(.opacity)
        }
    }

    @ViewBuilder
    private var pauseMark: some View {
        if isPaused {
            Text("paused")
                .font(Typography.mono(TVMetrics.label))
                .foregroundStyle(Palette.white)
                .opacity(Opacities.muted)
                .shadow(color: Palette.black.opacity(0.6), radius: Spacing.s6)
                .padding(TVMetrics.overscanInset)
                .transition(.opacity)
        }
    }

    private var current: TVGalleryFrame? {
        frames.indices.contains(index) ? frames[index] : frames.first
    }

    private var next: TVGalleryFrame? {
        guard frames.count > 1 else { return nil }
        return frames[(index + 1) % frames.count]
    }

    private func step(_ offset: Int) {
        guard frames.count > 1 else { return }
        withAnimation(Self.crossfade) {
            index = (index + offset + frames.count) % frames.count
        }
        steps += 1
    }

    private func cycle() async {
        guard frames.count > 1, !isPaused else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(Self.interval))
            guard !Task.isCancelled else { return }
            withAnimation(Self.crossfade) {
                index = (index + 1) % frames.count
            }
        }
    }
}

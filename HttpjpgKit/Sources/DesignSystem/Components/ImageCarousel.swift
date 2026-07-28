import SwiftUI

/// The one paged image carousel — work cards and `slideshow` bloks both render
/// through this, so arrows, counter and autoplay exist exactly once.
///
/// Slides come from a builder closure rather than a data array because the two
/// callers build their images differently (raw URLs vs. Storyblok assets), and
/// this layer must not know about either.
///
/// Autoplay runs on a `.task(id:)` loop, not `onReceive(Timer.publish…)`. The
/// timer version had a real bug: the publisher was a computed property, so
/// every body evaluation created a fresh publisher and re-subscribed — and
/// inside a `LazyVStack` the parent re-renders often enough that the countdown
/// reset before it ever fired. Autoplay looked simply dead. A task keyed on
/// stable state survives re-renders untouched.
public struct ImageCarousel<Slide: View>: View {
    private let count: Int
    private let aspectRatio: CGFloat
    private let autoplayInterval: TimeInterval?
    private let transitionDuration: TimeInterval
    private let showsArrows: Bool
    private let showsCounter: Bool
    private let slide: (Int) -> Slide

    @State private var index = 0
    @State private var hasInteracted = false

    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        count: Int,
        aspectRatio: CGFloat,
        autoplayInterval: TimeInterval? = nil,
        transitionDuration: TimeInterval = 0.3,
        showsArrows: Bool = true,
        showsCounter: Bool = false,
        @ViewBuilder slide: @escaping (Int) -> Slide
    ) {
        self.count = count
        self.aspectRatio = aspectRatio
        self.autoplayInterval = autoplayInterval
        self.transitionDuration = transitionDuration
        self.showsArrows = showsArrows
        self.showsCounter = showsCounter
        self.slide = slide
    }

    public var body: some View {
        if count == 1 {
            slide(0)
        } else if count > 1 {
            TabView(selection: $index) {
                ForEach(0 ..< count, id: \.self) { position in
                    slide(position)
                        .tag(position)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: PageLayout.cardWidth(viewport: viewportWidth) / aspectRatio)
            .simultaneousGesture(DragGesture().onChanged { _ in hasInteracted = true })
            .overlay(alignment: .bottomLeading) { counter }
            .overlay(alignment: .topTrailing) { navigation }
            .task(id: effectiveInterval) { await autoplay() }
        }
    }

    /// Arrows in the web's position — top right. Glass rather than the web's
    /// bare SVG: over arbitrary photography a translucent chip is the only
    /// thing that stays legible against both a white sky and a black shadow,
    /// and unlike the web there is no hover to reveal anything on.
    @ViewBuilder
    private var navigation: some View {
        if showsArrows {
            GlassGroup(spacing: Spacing.s2) {
                HStack(spacing: Spacing.s2) {
                    arrow("chevron.left", step: -1)
                    arrow("chevron.right", step: 1)
                }
            }
            .padding(Spacing.s3)
        }
    }

    private func arrow(_ symbol: String, step: Int) -> some View {
        Button {
            hasInteracted = true
            advance(by: step)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
                .glassBackground(in: .circle, tint: .black.opacity(0.55), interactive: true)
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.35), radius: 6)
        .accessibilityLabel(step < 0 ? "Previous slide" : "Next slide")
    }

    @ViewBuilder
    private var counter: some View {
        if showsCounter {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(pad(index + 1))/\(pad(count))")
                    .font(Typography.mono(Typography.Size.xs))
                    .tracking(Typography.Size.xs * 0.15)
                Text(Ascii.tape)
                    .font(Typography.mono(Typography.Size.xxs))
                    .opacity(0.5)
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.6), radius: 6)
            .padding(Spacing.s3)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    /// `nil` whenever autoplay must not run — one slide, Reduce Motion, the
    /// reader has touched the carousel, or it was never requested. Doubles as
    /// the task identity, so any change tears the loop down.
    private var effectiveInterval: TimeInterval? {
        guard count > 1, !reduceMotion, !hasInteracted else { return nil }
        return autoplayInterval
    }

    private func autoplay() async {
        guard let interval = effectiveInterval else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(interval))
            guard !Task.isCancelled, !hasInteracted else { return }
            advance(by: 1)
        }
    }

    /// Wraps in both directions, matching Swiper's `loop`.
    private func advance(by step: Int) {
        withAnimation(.easeInOut(duration: transitionDuration)) {
            index = (index + step + count) % count
        }
    }

    private func pad(_ value: Int) -> String {
        String(format: "%02d", value)
    }
}

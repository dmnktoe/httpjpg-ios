import SwiftUI
import Tokens

public struct ImageCarousel<Slide: View>: View {
    private let count: Int
    private let aspectRatio: CGFloat
    private let autoplayInterval: TimeInterval?
    private let transitionDuration: TimeInterval
    private let showsArrows: Bool
    private let showsCounter: Bool

    private let ownsRotation: (Int) -> Bool

    private let slide: (Int, CarouselSlide) -> Slide

    @State private var index = 0

    @State private var arrowTaps = 0

    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.mediaHeld) private var isHeld
    @Environment(\.chromeAccent) private var accent
    @Environment(\.chromeOnAccent) private var onAccent

    public init(
        count: Int,
        aspectRatio: CGFloat,
        autoplayInterval: TimeInterval? = nil,
        transitionDuration: TimeInterval = 0.3,
        showsArrows: Bool = true,
        showsCounter: Bool = false,
        ownsRotation: @escaping (Int) -> Bool = { _ in false },
        @ViewBuilder slide: @escaping (Int, CarouselSlide) -> Slide
    ) {
        self.count = count
        self.aspectRatio = aspectRatio
        self.autoplayInterval = autoplayInterval
        self.transitionDuration = transitionDuration
        self.showsArrows = showsArrows
        self.showsCounter = showsCounter
        self.ownsRotation = ownsRotation
        self.slide = slide
    }

    public var body: some View {
        if count == 1 {
            slide(0, .standalone)
        } else if count > 1 {
            TabView(selection: $index) {
                ForEach(0 ..< count, id: \.self) { position in
                    slide(position, context(for: position))
                        .tag(position)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: PageLayout.cardWidth(viewport: viewportWidth) / aspectRatio)
            .overlay(alignment: .bottomLeading) { counter }
            .overlay(alignment: .topTrailing) { navigation }

            .task(id: autoplayTick) { await autoplayStep() }
            .sensoryFeedback(.impact(weight: .light), trigger: arrowTaps)
        }
    }

    @ViewBuilder
    private var navigation: some View {
        if showsArrows {
            GlassGroup {
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
            arrowTaps += 1
            advance(by: step)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(onAccent ?? Palette.white)
                .frame(width: 34, height: 34)
                .contentShape(Circle())
                .glassBackground(
                    in: .circle,
                    tint: accent?.opacity(0.5) ?? Palette.black.opacity(0.55),
                    interactive: true
                )
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

    private var isAutoplayEnabled: Bool {
        count > 1 && !reduceMotion && !isHeld && autoplayInterval != nil
    }

    private var autoplayTick: Int {
        isAutoplayEnabled && !ownsRotation(index) ? index : -1
    }

    private func autoplayStep() async {
        guard autoplayTick >= 0, let interval = autoplayInterval else { return }
        try? await Task.sleep(for: .seconds(interval))
        guard !Task.isCancelled else { return }
        advance(by: 1)
    }

    private func context(for position: Int) -> CarouselSlide {
        CarouselSlide(isActive: position == index) { advance(by: 1) }
    }

    private func advance(by step: Int) {
        withAnimation(.easeInOut(duration: transitionDuration)) {
            index = (index + step + count) % count
        }
    }

    private func pad(_ value: Int) -> String {
        String(format: "%02d", value)
    }
}

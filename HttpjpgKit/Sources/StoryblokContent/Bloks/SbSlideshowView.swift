import Combine
import DesignSystem
import SwiftUI

/// Renders the `slideshow` blok — the Swift counterpart of `slideshow.tsx`.
///
/// The web's Swiper config comes across field for field: `autoplayDelay` drives
/// the timer, `speed` the transition, `showNavigation` the arrows,
/// `showCounter` the `01/04` strip. Autoplay stops when there is only one slide
/// and when the system asks for reduced motion, the same two conditions
/// `useReducedMotion()` guards on the web — and it stops for good once a finger
/// touches the carousel, because an image that keeps moving while you are
/// looking at it is worse on a phone than on a desktop.
public struct SbSlideshowView: View {
    private let blok: SlideshowBlok

    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var index = 0
    @State private var hasInteracted = false

    public init(blok: SlideshowBlok) {
        self.blok = blok
    }

    public var body: some View {
        if !blok.images.isEmpty {
            carousel
                .frame(height: height)
                .overlay(alignment: .bottomLeading) { counter }
                .overlay(alignment: .topTrailing) { navigation }
                .blokSpacing(blok.spacing)
                .onReceive(timer) { _ in advance(by: 1, isAutomatic: true) }
        }
    }

    private var carousel: some View {
        TabView(selection: $index) {
            ForEach(Array(blok.images.enumerated()), id: \.offset) { entry in
                AssetImage(asset: entry.element, aspectRatio: aspectRatio)
                    .tag(entry.offset)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .simultaneousGesture(DragGesture().onChanged { _ in hasInteracted = true })
    }

    /// Arrows in the web's position — top right, barely there until you look
    /// for them. Glass rather than the web's bare SVG: over arbitrary
    /// photography a translucent chip is the only thing that stays legible
    /// against both a white sky and a black shadow.
    @ViewBuilder
    private var navigation: some View {
        if blok.showsNavigation, blok.images.count > 1 {
            GlassGroup(spacing: Spacing.s2) {
                HStack(spacing: Spacing.s1) {
                    arrow("arrow.left", step: -1)
                    arrow("arrow.right", step: 1)
                }
            }
            .padding(.top, Spacing.s4)
            .padding(.trailing, Spacing.s4)
        }
    }

    private func arrow(_ symbol: String, step: Int) -> some View {
        Button {
            hasInteracted = true
            advance(by: step, isAutomatic: false)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .contentShape(Circle())
                .glassBackground(
                    in: .circle,
                    tint: .black.opacity(0.25),
                    interactive: true,
                    fallback: .black.opacity(0.35)
                )
        }
        .buttonStyle(.plain)
        .opacity(0.75)
        .accessibilityLabel(step < 0 ? "Previous slide" : "Next slide")
    }

    @ViewBuilder
    private var counter: some View {
        if blok.showsCounter, blok.images.count > 1 {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(pad(index + 1))/\(pad(blok.images.count))")
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

    /// Wraps in both directions, matching Swiper's `loop`.
    private func advance(by step: Int, isAutomatic: Bool) {
        guard blok.images.count > 1 else { return }
        if isAutomatic, hasInteracted || !isAutoplayEnabled { return }
        let count = blok.images.count
        withAnimation(.easeInOut(duration: blok.transitionDuration)) {
            index = (index + step + count) % count
        }
    }

    /// The publisher always exists — an optional one would change the view's
    /// type between states. When autoplay is off it simply ticks into a
    /// `advance` that declines, which is cheaper than it sounds at one tick a
    /// minute.
    private var timer: Publishers.Autoconnect<Timer.TimerPublisher> {
        Timer.publish(every: blok.autoplayInterval ?? 60, on: .main, in: .common).autoconnect()
    }

    private var isAutoplayEnabled: Bool {
        blok.images.count > 1 && !reduceMotion && blok.autoplayInterval != nil
    }

    /// One carousel needs one height. The CMS ratio wins; otherwise the first
    /// image's own proportions do, so the common case of a uniform set looks
    /// right without anyone configuring it.
    private var aspectRatio: CGFloat {
        blok.aspectRatio
            ?? ImageService.aspectRatio(of: blok.images.first?.filename)
            ?? 16.0 / 9.0
    }

    private var height: CGFloat {
        PageLayout.cardWidth(viewport: viewportWidth) / aspectRatio
    }

    private func pad(_ value: Int) -> String {
        String(format: "%02d", value)
    }
}

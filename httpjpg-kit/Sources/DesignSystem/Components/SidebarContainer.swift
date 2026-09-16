import SwiftUI
import Tokens

/// The left drawer: the page slides and scales aside, the menu sits underneath
/// it, and a scrim swallows the taps that would otherwise reach the page.
///
/// Every property the page animates on is a layer property — offset, scale,
/// corner radius. No colour filter (`grayscale`, `opacity`, `shadow`) is applied
/// to the page itself, because a filter forces SwiftUI to render the whole
/// subtree into an offscreen buffer, and a `glassEffect` inside that buffer has
/// no live backdrop left to sample. Keeping the page purely geometric is what
/// lets the bottom bar stay real glass for the length of the gesture instead of
/// being swapped out for a flat fill. The page shadow therefore lives on a
/// sibling plate behind the page, not on the page.
public struct SidebarContainer<Sidebar: View, Content: View>: View {
    private struct DragState {
        var translation: CGFloat = 0

        /// Translation at the moment the drag was accepted. Subtracting it keeps
        /// the page from jumping by `minimumDrag` on the first update.
        var origin: CGFloat = 0

        var isActive = false
    }

    @Binding private var isOpen: Bool

    private let maxWidth: CGFloat
    private let dragEnabled: Bool
    private let sidebar: Sidebar
    private let content: Content

    @GestureState(resetTransaction: Transaction(animation: Motion.drawer))
    private var drag = DragState()

    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.pageTheme) private var theme

    public init(
        isOpen: Binding<Bool>,
        maxWidth: CGFloat = 320,
        dragEnabled: Bool = true,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content
    ) {
        _isOpen = isOpen
        self.maxWidth = maxWidth
        self.dragEnabled = dragEnabled
        self.sidebar = sidebar()
        self.content = content()
    }

    public var body: some View {
        ZStack(alignment: .leading) {
            drawer
            page
            grabber
        }
        .background(theme.drawerBackground.ignoresSafeArea())
        .sensoryFeedback(.impact(weight: .light), trigger: isOpen)
        // Not a glass workaround: a paused video or marquee behind the drawer
        // looks the same as a running one and costs nothing.
        .environment(\.mediaHeld, isHolding)
        .environment(\.marqueeHeld, isHolding)
        .animation(motion, value: isOpen)
    }

    private var drawer: some View {
        sidebar
            .frame(width: width)
            .frame(maxHeight: .infinity, alignment: .top)
            .offset(x: (progress - 1) * Metrics.parallax)
            .opacity(drawerOpacity)
            .scrollDisabled(drag.isActive)
            .accessibilityHidden(!isOpen)
            .accessibilityAddTraits(isOpen ? .isModal : [])
            .accessibilityAction(.escape) { setOpen(false) }
            .simultaneousGesture(drawerDrag)
    }

    private var page: some View {
        content
            .overlay { scrim }
            .clipShape(pageShape)
            .background { shadowPlate }
            .scaleEffect(scale)
            .offset(x: offset)
            .scrollDisabled(isOpen || drag.isActive)
            .accessibilityHidden(isOpen)
            .simultaneousGesture(drawerDrag, including: isOpen ? .all : .subviews)
            .ignoresSafeArea()
    }

    private var scrim: some View {
        Rectangle()
            .fill(Palette.black.opacity(Metrics.scrimOpacity * Double(progress)))
            .allowsHitTesting(isOpen)
            .onTapGesture { setOpen(false) }
            .accessibilityHidden(true)
            .ignoresSafeArea()
    }

    /// The scaled page sits over the drawer; without a shadow its left edge
    /// reads flush against the menu.
    private var shadowPlate: some View {
        pageShape
            .fill(theme.background)
            .shadow(
                color: Palette.black.opacity(Opacities.dimmed * Double(progress)),
                radius: Spacing.s3 * progress
            )
    }

    private var pageShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Metrics.pageCorner, style: .continuous)
    }

    private var grabber: some View {
        Color.clear
            .frame(width: Metrics.grabWidth)
            .frame(maxHeight: .infinity)
            .contentShape(.rect)
            .gesture(drawerDrag)
            .allowsHitTesting(dragEnabled && !isOpen)
            .ignoresSafeArea()
    }

    private var drawerDrag: some Gesture {
        DragGesture(minimumDistance: Metrics.minimumDrag)
            .updating($drag) { value, state, _ in
                guard state.isActive || accepts(value) else { return }
                if !state.isActive {
                    state.isActive = true
                    state.origin = value.translation.width
                }
                state.translation = value.translation.width - state.origin
            }
            .onEnded { value in
                guard drag.isActive || accepts(value) else { return }
                setOpen(settlesOpen(after: value))
            }
    }

    private func accepts(_ value: DragGesture.Value) -> Bool {
        guard abs(value.translation.width) > abs(value.translation.height) else { return false }
        // Closing is always on offer; opening only from the screen edge, and only
        // where a navigation stack isn't already claiming the back swipe.
        guard !isOpen else { return true }
        return dragEnabled && value.startLocation.x <= Metrics.grabWidth
    }

    private func settlesOpen(after value: DragGesture.Value) -> Bool {
        let velocity = value.velocity.width
        guard abs(velocity) < Metrics.flickVelocity else { return velocity > 0 }
        return base + value.translation.width - drag.origin > width / 2
    }

    private var width: CGFloat {
        min(maxWidth, viewportWidth * Metrics.widthFraction)
    }

    private var base: CGFloat {
        isOpen ? width : 0
    }

    private var offset: CGFloat {
        let position = base + drag.translation
        guard position > width else { return max(position, 0) }
        return width + (position - width) / Metrics.rubberBand
    }

    private var progress: CGFloat {
        width > 0 ? min(offset / width, 1) : 0
    }

    private var scale: CGFloat {
        1 - Metrics.scaleDrop * progress
    }

    /// The closed page covers the drawer apart from its rounded corners, so the
    /// menu only has to fade in over the first sliver of the gesture.
    private var drawerOpacity: Double {
        min(Double(progress) * 3, 1)
    }

    private var isHolding: Bool {
        isOpen || drag.isActive
    }

    private var motion: Animation? {
        reduceMotion ? nil : Motion.drawer
    }

    private func setOpen(_ value: Bool) {
        withAnimation(motion) { isOpen = value }
    }
}

/// Outside `SidebarContainer` because a generic type cannot hold static stored
/// properties.
private enum Metrics {
    /// The drawer trails the page slightly instead of tracking it 1:1.
    static let parallax = Spacing.s10

    static let scaleDrop: CGFloat = 0.05

    static let pageCorner = Spacing.s12

    static let grabWidth = Spacing.s5

    static let minimumDrag: CGFloat = 10

    static let flickVelocity: CGFloat = 300

    /// Divides any drag past the open position so the drawer resists instead of
    /// tearing away from the screen edge.
    static let rubberBand: CGFloat = 4

    static let widthFraction: CGFloat = 0.82

    static let scrimOpacity = 0.35
}

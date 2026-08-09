import SwiftUI
import Tokens

/// The app-level drawer: the page slides right and scales back to reveal the
/// sidebar riding in underneath it. Open state lives with the caller; the
/// container owns the drag, the reveal choreography and the settle feedback,
/// so button, edge swipe and scrim all land the same way.
public struct SidebarContainer<Sidebar: View, Content: View>: View {
    private let maxWidth: CGFloat
    private let dragEnabled: Bool
    private let sidebar: Sidebar
    private let content: Content

    @Binding private var isOpen: Bool

    /// GestureState rather than State: the system can cancel a drag (incoming
    /// call, alert) without ever reaching onEnded, which used to strand the
    /// drawer mid-travel with every marquee frozen. GestureState also resets
    /// on cancellation, and the reset transaction replays the drawer spring so
    /// the abandoned drag settles instead of snapping.
    @GestureState(resetTransaction: Transaction(animation: Motion.drawer))
    private var drag: CGFloat = 0

    @GestureState private var isDragging = false

    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.pageTheme) private var theme

    /// The sidebar starts slightly under the page and rides the last stretch in.
    private static var parallax: CGFloat { Spacing.s10 }

    private static var scaleDrop: CGFloat { 0.05 }

    /// Strip along the leading edge that arms the open swipe, matching the
    /// system back-swipe region.
    private static var edgeWidth: CGFloat { Spacing.s5 }

    /// Past this horizontal speed the flick's direction decides open/close,
    /// no matter where the finger stopped.
    private static var flickVelocity: CGFloat { 300 }

    /// Dragging past full-open moves the page at a fraction of the finger
    /// instead of pinning it, so the drawer keeps feeling attached.
    private static var overshootDamping: CGFloat { 4 }

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
            sidebarPane
            main
        }
        .background(theme.drawerBackground.ignoresSafeArea())
        // One tick per state change here, so the toolbar button, the ✕, the
        // swipe and the scrim all feel identical.
        .sensoryFeedback(.impact(weight: .light), trigger: isOpen)
        .environment(\.marqueeHeld, isDragging)
        .animation(motion, value: isOpen)
    }

    private var sidebarPane: some View {
        sidebar
            .frame(width: width)
            .frame(maxHeight: .infinity, alignment: .top)
            .offset(x: (progress - 1) * Self.parallax)
            .opacity(Double(progress))
            .accessibilityHidden(!isOpen)
            .accessibilityAddTraits(isOpen ? .isModal : [])
            .accessibilityAction(.escape) { close() }
            // Its own copy of the drag, so a leftward swipe that starts on the
            // drawer closes it too — not only one on the pushed-aside page.
            .simultaneousGesture(drawerDrag)
    }

    private var main: some View {
        content
            .overlay {
                Rectangle()
                    .fill(Palette.black.opacity(0.35 * Double(progress)))
                    .onTapGesture { close() }
                    .allowsHitTesting(isOpen)
            }
            .clipShape(RoundedRectangle(cornerRadius: Radii.xxxl * progress, style: .continuous))
            .scaleEffect(1 - Self.scaleDrop * progress)
            .shadow(
                color: Palette.black.opacity(0.35 * Double(progress)),
                radius: Spacing.s6 * progress,
                x: -Spacing.s2 * progress
            )
            .offset(x: offset)
            .accessibilityHidden(isOpen)
            .simultaneousGesture(drawerDrag, including: gestureMask)
            .ignoresSafeArea()
    }

    private var drawerDrag: some Gesture {
        DragGesture(minimumDistance: 15)
            .updating($drag) { value, state, _ in
                guard tracks(value) else { return }
                state = value.translation.width
            }
            .updating($isDragging) { value, state, _ in
                if tracks(value) { state = true }
            }
            .onEnded { value in
                guard tracks(value) else { return }
                withAnimation(motion) {
                    isOpen = shouldOpen(after: value)
                }
            }
    }

    /// Closing must stay available even when pushed-in navigation turns the
    /// open swipe off, or an open drawer could only fall back to the scrim.
    private var gestureMask: GestureMask {
        dragEnabled || isOpen ? .all : .subviews
    }

    private var width: CGFloat {
        min(maxWidth, viewportWidth * 0.82)
    }

    private var base: CGFloat {
        isOpen ? width : 0
    }

    private var offset: CGFloat {
        let position = base + drag
        guard position > 0 else { return 0 }
        guard position > width else { return position }
        return width + (position - width) / Self.overshootDamping
    }

    private var progress: CGFloat {
        width > 0 ? min(offset / width, 1) : 0
    }

    private var motion: Animation? {
        reduceMotion ? nil : Motion.drawer
    }

    private func shouldOpen(after value: DragGesture.Value) -> Bool {
        let velocity = value.velocity.width
        guard abs(velocity) < Self.flickVelocity else { return velocity > 0 }
        return base + value.translation.width > width / 2
    }

    private func tracks(_ value: DragGesture.Value) -> Bool {
        guard abs(value.translation.width) > abs(value.translation.height) else { return false }
        return isOpen || value.startLocation.x <= Self.edgeWidth
    }

    private func close() {
        withAnimation(motion) { isOpen = false }
    }
}

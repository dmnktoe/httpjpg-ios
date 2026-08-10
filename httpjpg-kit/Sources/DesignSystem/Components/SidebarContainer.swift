import SwiftUI
import Tokens

public struct SidebarContainer<Sidebar: View, Content: View>: View {
    private let maxWidth: CGFloat
    private let dragEnabled: Bool
    private let sidebar: Sidebar
    private let content: Content

    @Binding private var isOpen: Bool

    private struct DragState {
        var translation: CGFloat = 0

        var origin: CGFloat = 0

        /// Latched on the first horizontal-dominant update. The dominance
        /// check only arms the drag; gating every update on it froze the
        /// drawer mid-travel whenever an arcing thumb drifted vertical.
        var isArmed = false
    }

    @GestureState(resetTransaction: Transaction(animation: Motion.drawer))
    private var drag = DragState()

    @State private var isSettling = false

    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.pageTheme) private var theme

    private static var parallax: CGFloat { Spacing.s10 }

    private static var scaleDrop: CGFloat { 0.05 }

    private static var edgeWidth: CGFloat { Spacing.s5 }

    private static var flickVelocity: CGFloat { 300 }

    private static var overshootDamping: CGFloat { 4 }

    /// Off the radius scale on purpose: this one answers to the display's own
    /// corner, not to the type of surface it is. Kept under it, so the wedges
    /// stay behind the hardware mask while the drawer is shut.
    private static var pageCorner: CGFloat { Spacing.s12 }

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

            openEdge
                .allowsHitTesting(dragEnabled && !isOpen)
        }
        .background(theme.drawerBackground.ignoresSafeArea())
        .sensoryFeedback(.impact(weight: .light), trigger: isOpen)
        .environment(\.mediaHeld, ambientHeld)
        .environment(\.chromeHeld, ambientHeld)
        .animation(motion, value: isOpen)
        .task(id: isOpen) {
            isSettling = true
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            isSettling = false
        }
    }

    private var sidebarPane: some View {
        sidebar
            .scrollDisabled(drag.isArmed)
            .frame(width: width)
            .frame(maxHeight: .infinity, alignment: .top)
            .offset(x: (progress - 1) * Self.parallax)
            .opacity(paneOpacity)
            .accessibilityHidden(!isOpen)
            .accessibilityAddTraits(isOpen ? .isModal : [])
            .accessibilityAction(.escape) { close() }
            .simultaneousGesture(drawerDrag)
    }

    private var main: some View {
        content
            .scrollDisabled(drag.isArmed || isOpen)
            .overlay {
                Rectangle()
                    .fill(Palette.black)
                    .opacity(0.35 * Double(progress))
                    .onTapGesture { close() }
                    .allowsHitTesting(isOpen)
            }
            .overlay {
                CornerCutout(radius: Self.pageCorner)
                    .fill(theme.drawerBackground, style: FillStyle(eoFill: true))
                    .allowsHitTesting(false)
            }
            .modifier(PageTransform(offset: offset, scale: 1 - Self.scaleDrop * progress))
            .accessibilityHidden(isOpen)
            .environment(\.marqueeHeld, ambientHeld)
            .simultaneousGesture(drawerDrag, including: isOpen ? .all : .subviews)
            .ignoresSafeArea()
    }

    private var ambientHeld: Bool {
        isOpen || drag.isArmed || isSettling
    }

    private var openEdge: some View {
        Color.clear
            .frame(width: Self.edgeWidth)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(drawerDrag)
            .ignoresSafeArea()
    }

    private var drawerDrag: some Gesture {
        DragGesture(minimumDistance: 10)
            .updating($drag) { value, state, _ in
                guard state.isArmed || tracks(value) else { return }
                if !state.isArmed {
                    state.isArmed = true
                    state.origin = value.translation.width
                }
                state.translation = value.translation.width - state.origin
            }
            .onEnded { value in
                guard drag.isArmed || tracks(value) else { return }
                withAnimation(motion) {
                    isOpen = shouldOpen(after: value)
                }
            }
    }

    private var width: CGFloat {
        min(maxWidth, viewportWidth * 0.82)
    }

    private var base: CGFloat {
        isOpen ? width : 0
    }

    private var offset: CGFloat {
        let position = base + drag.translation
        guard position > 0 else { return 0 }
        guard position > width else { return position }
        return width + (position - width) / Self.overshootDamping
    }

    private var progress: CGFloat {
        width > 0 ? min(offset / width, 1) : 0
    }

    private var paneOpacity: Double {
        min(Double(progress) * 3, 1)
    }

    private var motion: Animation? {
        reduceMotion ? nil : Motion.drawer
    }

    private func shouldOpen(after value: DragGesture.Value) -> Bool {
        let velocity = value.velocity.width
        guard abs(velocity) < Self.flickVelocity else { return velocity > 0 }
        return base + value.translation.width - drag.origin > width / 2
    }

    private func tracks(_ value: DragGesture.Value) -> Bool {
        guard abs(value.translation.width) > abs(value.translation.height) else { return false }
        return isOpen || value.startLocation.x <= Self.edgeWidth
    }

    private func close() {
        withAnimation(motion) { isOpen = false }
    }
}

/// A `GeometryEffect` rather than `scaleEffect` + `offset`: those two re-render
/// the page at the new scale every frame, this hands Core Animation one
/// projection to apply to what it already has.
private struct PageTransform: GeometryEffect {
    var offset: CGFloat
    var scale: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(offset, scale) }
        set {
            offset = newValue.first
            scale = newValue.second
        }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let x = size.width / 2
        let y = size.height / 2
        return ProjectionTransform(
            CGAffineTransform(translationX: offset, y: 0)
                .translatedBy(x: x, y: y)
                .scaledBy(x: scale, y: scale)
                .translatedBy(x: -x, y: -y)
        )
    }
}

/// The four corner wedges, painted over the page in the drawer's own colour.
/// Clipping the page to a rounded rect is a mask, and a mask means the whole
/// screen goes through an offscreen pass on every frame it moves.
private struct CornerCutout: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        path.addPath(RoundedRectangle(cornerRadius: radius, style: .continuous).path(in: rect))
        return path
    }
}

import SwiftUI
import Tokens

public struct SidebarContainer<Sidebar: View, Content: View>: View {
    private let maxWidth: CGFloat
    private let dragEnabled: Bool
    private let sidebar: Sidebar
    private let content: Content

    @Binding private var isOpen: Bool

    @GestureState(resetTransaction: Transaction(animation: Motion.drawer))
    private var drag: CGFloat = 0

    @GestureState private var isDragging = false

    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.pageTheme) private var theme

    private static var parallax: CGFloat { Spacing.s10 }

    private static var scaleDrop: CGFloat { 0.05 }

    private static var edgeWidth: CGFloat { Spacing.s5 }

    private static var flickVelocity: CGFloat { 300 }

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

            if dragEnabled && !isOpen {
                openEdge
            }
        }
        .background(theme.drawerBackground.ignoresSafeArea())
        .sensoryFeedback(.impact(weight: .light), trigger: isOpen)
        .environment(\.marqueeHeld, isDragging)
        .animation(motion, value: isOpen)
    }

    private var sidebarPane: some View {
        sidebar
            .scrollDisabled(isDragging)
            .frame(width: width)
            .frame(maxHeight: .infinity, alignment: .top)
            .offset(x: (progress - 1) * Self.parallax)
            .opacity(Double(progress))
            .accessibilityHidden(!isOpen)
            .accessibilityAddTraits(isOpen ? .isModal : [])
            .accessibilityAction(.escape) { close() }
            .simultaneousGesture(drawerDrag)
    }

    private var main: some View {
        content
            .scrollDisabled(isDragging)
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
            .simultaneousGesture(drawerDrag, including: isOpen ? .all : .subviews)
            .ignoresSafeArea()
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

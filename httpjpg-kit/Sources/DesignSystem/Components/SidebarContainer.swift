import SwiftUI
import Tokens

public struct SidebarContainer<Sidebar: View, Content: View, Chrome: View>: View {
    private let maxWidth: CGFloat
    private let dragEnabled: Bool
    private let sidebar: Sidebar
    private let content: Content
    private let chrome: Chrome

    @Binding private var isOpen: Bool

    private struct DragState {
        var translation: CGFloat = 0

        var isArmed = false
    }

    @GestureState(resetTransaction: Transaction(animation: Motion.drawer))
    private var drag = DragState()

    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.viewportHeight) private var viewportHeight
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.pageTheme) private var theme

    private static var edgeWidth: CGFloat { Spacing.s5 }

    private static var pageCorner: CGFloat { Spacing.s12 }

    public init(
        isOpen: Binding<Bool>,
        maxWidth: CGFloat = 320,
        dragEnabled: Bool = true,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content,
        @ViewBuilder chrome: () -> Chrome
    ) {
        _isOpen = isOpen
        self.maxWidth = maxWidth
        self.dragEnabled = dragEnabled
        self.sidebar = sidebar()
        self.content = content()
        self.chrome = chrome()
    }

    public var body: some View {
        ZStack(alignment: .leading) {
            sidebarLayer
            pageLayer

            edgeLayer
                .allowsHitTesting(dragEnabled && !isOpen)
        }
        .overlay(alignment: .bottom) {
            chromeLayer
        }
        .background(theme.drawerBackground.ignoresSafeArea())
        .sensoryFeedback(.impact(weight: .light), trigger: isOpen)
        .environment(\.mediaHeld, holdsAmbientContent)
        .animation(motion, value: isOpen)
    }

    private var sidebarLayer: some View {
        sidebar
            .scrollDisabled(drag.isArmed)
            .frame(width: width)
            .frame(maxHeight: .infinity, alignment: .top)
            .offset(x: geometry.sidebarOffset)
            .opacity(geometry.sidebarOpacity)
            .accessibilityHidden(!isOpen)
            .accessibilityAddTraits(isOpen ? .isModal : [])
            .accessibilityAction(.escape) { close() }
            .simultaneousGesture(drawerDrag)
    }

    private var pageLayer: some View {
        content
            .scrollDisabled(drag.isArmed || isOpen)
            .overlay {
                Rectangle()
                    .fill(Palette.black)
                    .opacity(0.35 * Double(geometry.progress))
                    .onTapGesture { close() }
                    .allowsHitTesting(isOpen)
                    .ignoresSafeArea()
            }
            .clipShape(RoundedRectangle(cornerRadius: Self.pageCorner, style: .continuous))
            .shadow(color: pageShadow, radius: Spacing.s3)
            .scaleEffect(geometry.pageScale)
            .offset(x: geometry.position)
            .accessibilityHidden(isOpen)
            .environment(\.marqueeHeld, holdsAmbientContent)
            .simultaneousGesture(drawerDrag, including: isOpen ? .all : .subviews)
            .ignoresSafeArea()
    }

    private var chromeLayer: some View {
        chrome
            .frame(maxWidth: .infinity)
            .scaleEffect(geometry.pageScale)
            .offset(
                x: geometry.position,
                y: geometry.chromeVerticalOffset(viewportHeight: viewportHeight)
            )
            .opacity(1 - 0.35 * Double(geometry.progress))
            .allowsHitTesting(!isOpen && !drag.isArmed)
            .accessibilityHidden(isOpen)
            .environment(\.marqueeHeld, holdsAmbientContent)
            .ignoresSafeArea()
    }

    private var geometry: SidebarDrawerGeometry {
        SidebarDrawerGeometry(
            width: width,
            isOpen: isOpen,
            translation: drag.translation
        )
    }

    private var holdsAmbientContent: Bool {
        isOpen || drag.isArmed
    }

    private var edgeLayer: some View {
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
                }
                state.translation = value.translation.width
            }
            .onEnded { value in
                guard drag.isArmed || tracks(value) else { return }
                withAnimation(motion) {
                    isOpen = geometry.settlesOpen(
                        projectedTranslation: value.predictedEndTranslation.width
                    )
                }
            }
    }

    private var width: CGFloat {
        min(maxWidth, viewportWidth * 0.82)
    }

    private var pageShadow: Color {
        Palette.black.opacity(Opacities.dimmed * Double(geometry.progress))
    }

    private var motion: Animation? {
        reduceMotion ? nil : Motion.drawer
    }

    private func tracks(_ value: DragGesture.Value) -> Bool {
        guard dragEnabled || isOpen else { return false }
        guard abs(value.translation.width) > abs(value.translation.height) else { return false }
        return isOpen || value.startLocation.x <= Self.edgeWidth
    }

    private func close() {
        withAnimation(motion) { isOpen = false }
    }
}

extension SidebarContainer where Chrome == EmptyView {
    public init(
        isOpen: Binding<Bool>,
        maxWidth: CGFloat = 320,
        dragEnabled: Bool = true,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            isOpen: isOpen,
            maxWidth: maxWidth,
            dragEnabled: dragEnabled,
            sidebar: sidebar,
            content: content,
            chrome: { EmptyView() }
        )
    }
}

struct SidebarDrawerGeometry {
    private static let scaleDrop: CGFloat = 0.05
    private static let sidebarParallax: CGFloat = Spacing.s10
    private static let overshootDamping: CGFloat = 4

    let width: CGFloat
    let isOpen: Bool
    let translation: CGFloat

    var position: CGFloat {
        let proposed = restingPosition + translation
        guard proposed > 0 else { return 0 }
        guard proposed > width else { return proposed }
        return width + (proposed - width) / Self.overshootDamping
    }

    var progress: CGFloat {
        guard width > 0 else { return 0 }
        return min(position / width, 1)
    }

    var pageScale: CGFloat {
        1 - Self.scaleDrop * progress
    }

    var sidebarOffset: CGFloat {
        (progress - 1) * Self.sidebarParallax
    }

    var sidebarOpacity: Double {
        min(Double(progress) * 3, 1)
    }

    func chromeVerticalOffset(viewportHeight: CGFloat) -> CGFloat {
        -viewportHeight * (1 - pageScale) / 2
    }

    func settlesOpen(projectedTranslation: CGFloat) -> Bool {
        restingPosition + projectedTranslation > width / 2
    }

    private var restingPosition: CGFloat {
        isOpen ? width : 0
    }
}

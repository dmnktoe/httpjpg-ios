import SwiftUI

public struct SidebarContainer<Sidebar: View, Content: View>: View {
    private let maxWidth: CGFloat
    private let dragEnabled: Bool
    private let sidebar: Sidebar
    private let content: Content

    @Binding private var isOpen: Bool
    @State private var drag: CGFloat = 0
    @State private var isDragging = false

    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.pageTheme) private var theme

    private static var parallax: CGFloat { Spacing.s10 }

    private static var scaleDrop: CGFloat { 0.05 }

    private static var edgeWidth: CGFloat { Spacing.s5 }

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
            sidebar
                .frame(width: width)
                .frame(maxHeight: .infinity, alignment: .top)
                .background(theme.drawerBackground.ignoresSafeArea())
                .offset(x: (progress - 1) * Self.parallax)
                .opacity(Double(progress))
                .accessibilityHidden(!isOpen)
                .accessibilityAction(.escape) { close() }

            main
        }
        .environment(\.marqueeHeld, isDragging)
        .animation(motion, value: isOpen)
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
            .simultaneousGesture(drawerDrag, including: dragEnabled ? .all : .subviews)
            .ignoresSafeArea()
    }

    private var drawerDrag: some Gesture {
        DragGesture(minimumDistance: 15)
            .onChanged { value in
                guard tracks(value) else { return }
                isDragging = true
                drag = value.translation.width
            }
            .onEnded { value in
                let shouldOpen = tracks(value)
                    ? base + value.predictedEndTranslation.width > width / 2
                    : isOpen
                isDragging = false
                withAnimation(motion) {
                    drag = 0
                    isOpen = shouldOpen
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
        min(max(base + drag, 0), width)
    }

    private var progress: CGFloat {
        width > 0 ? offset / width : 0
    }

    private var motion: Animation? {
        reduceMotion ? nil : Motion.drawer
    }

    private func tracks(_ value: DragGesture.Value) -> Bool {
        guard abs(value.translation.width) > abs(value.translation.height) else { return false }
        return isOpen || value.startLocation.x <= Self.edgeWidth
    }

    private func close() {
        withAnimation(motion) { isOpen = false }
    }
}

import SwiftUI

/// Drawer that pushes the main view aside instead of covering it — the shape of
/// navigation the AI chat apps popularised. The main view keeps its full width
/// and slides; the corner radius, the slight scale down and the shadow are what
/// sell it as a card lifted off the drawer underneath.
public struct SidebarContainer<Sidebar: View, Content: View>: View {
    private let maxWidth: CGFloat
    private let dragEnabled: Bool
    private let sidebar: Sidebar
    private let content: Content

    @Binding private var isOpen: Bool
    @State private var drag: CGFloat = 0

    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The drawer trails the content a little so it reads as a layer underneath
    /// rather than a panel arriving under its own steam.
    private static var parallax: CGFloat { Spacing.s10 }

    private static var scaleDrop: CGFloat { 0.05 }

    /// Leading strip that opens the drawer, roughly the width of the system's
    /// own edge gestures.
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
                .offset(x: (progress - 1) * Self.parallax)
                .opacity(Double(progress))
                .accessibilityHidden(!isOpen)
                .accessibilityAction(.escape) { close() }

            main
        }
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
            // `.subviews` keeps the drawer's own drag out of the way without
            // disabling the gestures inside the content (nav-stack back swipe).
            .simultaneousGesture(drawerDrag, including: dragEnabled ? .all : .subviews)
    }

    private var drawerDrag: some Gesture {
        DragGesture(minimumDistance: 15)
            .onChanged { value in
                guard tracks(value) else { return }
                drag = value.translation.width
            }
            .onEnded { value in
                let shouldOpen = tracks(value)
                    ? base + value.predictedEndTranslation.width > width / 2
                    : isOpen
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
        reduceMotion ? nil : .interactiveSpring(response: 0.4, dampingFraction: 0.85)
    }

    private func tracks(_ value: DragGesture.Value) -> Bool {
        guard abs(value.translation.width) > abs(value.translation.height) else { return false }
        // Closed, only a swipe off the leading edge counts: a drag that starts
        // anywhere else belongs to the paging carousels inside the content.
        return isOpen || value.startLocation.x <= Self.edgeWidth
    }

    private func close() {
        withAnimation(motion) { isOpen = false }
    }
}

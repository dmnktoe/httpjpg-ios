import SwiftUI
import Tokens

private struct TabSlidePositionKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var tabSlidePosition: CGFloat {
        get { self[TabSlidePositionKey.self] }
        set { self[TabSlidePositionKey.self] = newValue }
    }
}

public extension View {
    // Slides a tab's root page in from the side its tab sits on when
    // `TabSwitcher` brings it on stage. Apply it inside the page's scroll view,
    // so the navigation bar, its title and the scroll edge effect stay put and
    // only the page itself travels.
    func tabPageSlide() -> some View {
        modifier(TabPageSlide())
    }
}

private struct TabPageSlide: ViewModifier {
    @Environment(\.tabSlidePosition) private var position
    @Environment(\.viewportWidth) private var viewportWidth

    func body(content: Content) -> some View {
        content.modifier(TabSlideOffset(position: position, travel: viewportWidth))
    }
}

// Movement only, no fade: the pages carry glass (the variant picker), and
// glass under a partial opacity flickers. A full-width run keeps the page
// offscreen until it moves, so it never pops in.
private struct TabSlideOffset: ViewModifier, Animatable {
    var position: CGFloat
    let travel: CGFloat

    var animatableData: CGFloat {
        get { position }
        set { position = newValue }
    }

    func body(content: Content) -> some View {
        content.offset(x: position * travel)
    }
}

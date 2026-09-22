import SwiftUI

public extension View {
    /// Fades content out under floating chrome — the tab bar, a drawer's own
    /// header — where a defined edge would cut the page off mid-scroll.
    func softScrollEdges(_ edges: Edge.Set = .all) -> some View {
        modifier(ScrollEdges(style: .soft, edges: edges))
    }

    /// For a page under a titled navigation bar: a hard top edge, so the bar
    /// separates itself once content scrolls beneath it and leaves the page
    /// alone at rest, and a soft bottom one under the floating tab bar.
    ///
    /// This is the system's own behaviour — `.soft` on the top edge is what
    /// dissolved the rule in the first place.
    func navigationScrollEdges() -> some View {
        modifier(ScrollEdges(style: .hard, edges: .top))
            .modifier(ScrollEdges(style: .soft, edges: .bottom))
    }
}

private struct ScrollEdges: ViewModifier {
    enum Style {
        case soft
        case hard
    }

    let style: Style
    let edges: Edge.Set

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            switch style {
            case .soft: content.scrollEdgeEffectStyle(.soft, for: edges)
            case .hard: content.scrollEdgeEffectStyle(.hard, for: edges)
            }
        } else {
            content
        }
    }
}

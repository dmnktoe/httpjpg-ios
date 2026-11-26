import SwiftUI

public extension View {
    func softScrollEdges(_ edges: Edge.Set = .all) -> some View {
        modifier(ScrollEdges(style: .soft, edges: edges))
    }

    func navigationScrollEdges() -> some View {
        modifier(ScrollEdges(style: .hard, edges: .top))
            .modifier(ScrollEdges(style: .soft, edges: .bottom))
    }

    func hiddenScrollEdges(_ edges: Edge.Set = .all) -> some View {
        modifier(HiddenScrollEdges(edges: edges))
    }
}

private struct HiddenScrollEdges: ViewModifier {
    let edges: Edge.Set

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.scrollEdgeEffectHidden(true, for: edges)
        } else {
            content
        }
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

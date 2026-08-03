import SwiftUI

public extension View {
    func softScrollEdges(_ edges: Edge.Set = .all) -> some View {
        modifier(SoftScrollEdges(edges: edges))
    }
}

private struct SoftScrollEdges: ViewModifier {
    let edges: Edge.Set

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.scrollEdgeEffectStyle(.soft, for: edges)
        } else {
            content
        }
    }
}

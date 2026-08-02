import SwiftUI

/// Softens where scrolling content runs under the floating glass chrome. The
/// app has no opaque bars to hide behind, so without this the content simply
/// slides under the pills with a hard edge.
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

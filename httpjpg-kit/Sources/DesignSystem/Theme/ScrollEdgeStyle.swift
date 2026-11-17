import SwiftUI

public extension View {
    func softScrollEdges(_ edges: Edge.Set = .all) -> some View {
        modifier(ScrollEdges(style: .soft, edges: edges.subtracting(.top)))
            .modifier(ShortTopScrollEdge(isActive: edges.contains(.top)))
    }

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

private struct ShortTopScrollEdge: ViewModifier {
    let isActive: Bool

    @State private var edge = TopEdge()

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *), isActive {
            content
                .scrollEdgeEffectHidden(true, for: .top)
                .onGeometryChange(for: TopEdge.self) { proxy in
                    TopEdge(
                        offset: max(proxy.frame(in: .global).minY, 0),
                        inset: proxy.safeAreaInsets.top
                    )
                } action: { edge = $0 }
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .mask {
                            LinearGradient(
                                stops: [
                                    .init(color: .black, location: 0),
                                    .init(color: .black, location: 0.5),
                                    .init(color: .clear, location: 1),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                        .frame(height: max(edge.offset, edge.inset))
                        .offset(y: -edge.offset)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
        } else {
            content
        }
    }
}

private struct TopEdge: Equatable {
    var offset: CGFloat = 0
    var inset: CGFloat = 0
}

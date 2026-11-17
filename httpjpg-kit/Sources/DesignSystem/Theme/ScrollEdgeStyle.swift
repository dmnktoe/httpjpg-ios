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

/// The system's soft top edge has no height setting and blurs well past the
/// navigation bar, into the first rows of the page. This one stays inside the
/// bar: full blur behind the status bar, faded out by the bar's bottom edge.
private struct ShortTopScrollEdge: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *), isActive {
            content
                .scrollEdgeEffectHidden(true, for: .top)
                .overlay {
                    GeometryReader { proxy in
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
                            .frame(width: proxy.size.width, height: proxy.safeAreaInsets.top)
                    }
                    .ignoresSafeArea(.container, edges: .top)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
        } else {
            content
        }
    }
}

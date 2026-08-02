import SwiftUI

/// Pairs a source view with the screen it pushes to, so the destination grows
/// out of the thing that was tapped. Both halves need the same id and
/// namespace; without a matching source the push falls back to a plain slide.
public extension View {
    func zoomTransitionSource(id: some Hashable, in namespace: Namespace.ID) -> some View {
        modifier(ZoomTransitionSource(id: id, namespace: namespace))
    }

    func zoomTransitionDestination(id: some Hashable, in namespace: Namespace.ID) -> some View {
        modifier(ZoomTransitionDestination(id: id, namespace: namespace))
    }
}

private struct ZoomTransitionSource<ID: Hashable>: ViewModifier {
    let id: ID
    let namespace: Namespace.ID

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
    }
}

private struct ZoomTransitionDestination<ID: Hashable>: ViewModifier {
    let id: ID
    let namespace: Namespace.ID

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            content
        }
    }
}

import SwiftUI

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

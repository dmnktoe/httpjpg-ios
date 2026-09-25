import SwiftUI

public extension View {
    func floatingBottomBar<Bar: View>(@ViewBuilder content: () -> Bar) -> some View {
        modifier(FloatingBar(edge: .bottom, bar: content()))
    }

    func floatingTopBar<Bar: View>(@ViewBuilder content: () -> Bar) -> some View {
        modifier(FloatingBar(edge: .top, bar: content()))
    }
}

private struct FloatingBar<Bar: View>: ViewModifier {
    let edge: VerticalEdge
    let bar: Bar

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.safeAreaBar(edge: edge, spacing: 0) { bar }
        } else {
            content.safeAreaInset(edge: edge, spacing: 0) {
                if edge == .top {
                    bar.background(.bar)
                } else {
                    bar
                }
            }
        }
    }
}

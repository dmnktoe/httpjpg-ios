import SwiftUI

public extension View {
    func floatingBottomBar<Bar: View>(@ViewBuilder content: () -> Bar) -> some View {
        modifier(FloatingBar(bar: content()))
    }
}

private struct FloatingBar<Bar: View>: ViewModifier {
    let bar: Bar

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.safeAreaBar(edge: .bottom, spacing: 0) { bar }
        } else {
            content.safeAreaInset(edge: .bottom, spacing: 0) { bar }
        }
    }
}

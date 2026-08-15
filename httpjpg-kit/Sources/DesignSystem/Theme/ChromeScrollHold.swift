import SwiftUI

/// Bubbles scroll activity so floating glass can fall back to solid fills (see `chromeHeld`).
struct ChromeScrollHoldKey: PreferenceKey {
    static let defaultValue = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

public extension View {
    /// While the scroll view is dragging or decelerating, prefer solid chrome over live glass.
    func holdsChromeWhileScrolling() -> some View {
        modifier(ChromeScrollHoldModifier())
    }
}

private struct ChromeScrollHoldModifier: ViewModifier {
    @State private var isHeld = false

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .onScrollPhaseChange { _, phase in
                    let held = phase != .idle
                    guard held != isHeld else { return }
                    isHeld = held
                }
                .preference(key: ChromeScrollHoldKey.self, value: isHeld)
        } else {
            content
        }
    }
}

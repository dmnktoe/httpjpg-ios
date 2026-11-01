import SwiftUI

// The package tests compile this target for the iOS simulator, where .card and
// focusSection() do not exist; there a plain button and no section stand in.
extension View {
    @ViewBuilder
    func tvCardStyle() -> some View {
        #if os(tvOS)
        buttonStyle(.card)
        #else
        buttonStyle(.plain)
        #endif
    }

    @ViewBuilder
    func tvFocusSection() -> some View {
        #if os(tvOS)
        focusSection()
        #else
        self
        #endif
    }
}

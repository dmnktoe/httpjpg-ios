import SwiftUI

public struct FadeInUp: ViewModifier {
    private let distance: CGFloat
    private let duration: TimeInterval

    @State private var isShown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(distance: CGFloat = 14, duration: TimeInterval = 0.3) {
        self.distance = distance
        self.duration = duration
    }

    public func body(content: Content) -> some View {
        content
            .opacity(isShown ? 1 : 0)
            .offset(y: isShown ? 0 : distance)
            .animation(entrance, value: isShown)
            .task { isShown = true }
    }

    private var entrance: Animation? {
        guard !reduceMotion else { return nil }
        return .easeOut(duration: duration)
    }
}

public extension View {
    func fadeInUp(distance: CGFloat = 14, duration: TimeInterval = 0.3) -> some View {
        modifier(FadeInUp(distance: distance, duration: duration))
    }
}

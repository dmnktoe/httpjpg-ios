import SwiftUI

public struct SkeletonBlock: View {
    private let width: CGFloat?
    private let height: CGFloat?

    @State private var isDimmed = false
    @Environment(\.pageTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// A nil height fills whatever container proposes — for media boxes
    /// waiting on their first frame.
    public init(width: CGFloat? = nil, height: CGFloat? = Typography.Size.base) {
        self.width = width
        self.height = height
    }

    public var body: some View {
        Rectangle()
            .fill(theme.border)
            .frame(maxWidth: width ?? .infinity, maxHeight: height == nil ? .infinity : nil)
            .frame(height: height)
            .opacity(isDimmed ? Opacities.dimmed : 1)
            .animation(pulse, value: isDimmed)
            .onAppear { isDimmed = true }
            .accessibilityHidden(true)
    }

    private var pulse: Animation? {
        guard !reduceMotion else { return nil }
        return .easeInOut(duration: 0.9).repeatForever(autoreverses: true)
    }
}

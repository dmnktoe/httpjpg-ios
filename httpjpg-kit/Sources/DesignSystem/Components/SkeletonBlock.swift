import SwiftUI

/// A pulsing bar that stands in for a line of text or a piece of media while it loads.
///
/// Laid out at the size of the thing it replaces, so the real content drops into place
/// instead of pushing the page around when it arrives.
public struct SkeletonBlock: View {
    private let width: CGFloat?
    private let height: CGFloat

    @State private var isDimmed = false
    @Environment(\.pageTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(width: CGFloat? = nil, height: CGFloat = Typography.Size.base) {
        self.width = width
        self.height = height
    }

    public var body: some View {
        Rectangle()
            .fill(theme.border)
            .frame(maxWidth: width ?? .infinity)
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

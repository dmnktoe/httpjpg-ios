import SwiftUI

/// The rainbow loading strip from `@httpjpg/ui`'s `<Loading>`.
///
/// This is the one place the design system deliberately steps outside the
/// token palette — the same exception the web makes for the loading gradient.
public struct RainbowBar: View {
    private let height: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(height: CGFloat = 3) {
        self.height = height
    }

    private static let stops: [Color] = [
        Color(hex: 0xFF0000),
        Color(hex: 0xFF7F00),
        Color(hex: 0xFFFF00),
        Color(hex: 0x00FF00),
        Color(hex: 0x0000FF),
        Color(hex: 0x4B0082),
        Color(hex: 0x9400D3),
        Color(hex: 0xFF0000),
    ]

    public var body: some View {
        if reduceMotion {
            gradient
                .frame(height: height)
        } else {
            TimelineView(.animation) { timeline in
                let cycle = timeline.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: 2) / 2
                gradient
                    .scaleEffect(x: 2, anchor: .leading)
                    .offset(x: -CGFloat(cycle) * 200)
                    .frame(height: height)
                    .clipped()
            }
            .frame(height: height)
        }
    }

    private var gradient: some View {
        LinearGradient(colors: Self.stops, startPoint: .leading, endPoint: .trailing)
    }
}

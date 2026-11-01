import SwiftUI

struct TVKenBurnsFrame: View {
    enum Drift {
        case towardsTopLeading
        case towardsBottomTrailing
    }

    let filename: String
    let drift: Drift
    let duration: TimeInterval
    var isStill = false

    @State private var isZoomed = false

    var body: some View {
        Color.clear
            .overlay {
                TVImage(filename: filename, targetWidth: TVMetrics.screenWidth)
                    .scaleEffect(isZoomed ? 1.14 : 1.02, anchor: anchor)
            }
            .clipped()
            .onAppear {
                guard !isStill else { return }
                withAnimation(.linear(duration: duration)) {
                    isZoomed = true
                }
            }
    }

    private var anchor: UnitPoint {
        switch drift {
        case .towardsTopLeading: return .topLeading
        case .towardsBottomTrailing: return .bottomTrailing
        }
    }
}

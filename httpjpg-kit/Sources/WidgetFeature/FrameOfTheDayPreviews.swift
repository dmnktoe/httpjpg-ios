#if DEBUG
import SwiftUI
import WidgetKit

extension FrameOfTheDayEntry {
    static let sample = FrameOfTheDayEntry(
        date: Date(timeIntervalSince1970: 0),
        image: WidgetPreviewSample.artwork(seed: 3, size: CGSize(width: 900, height: 900))
    )

    static let sampleFailure = FrameOfTheDayEntry.failure("no frames published")
}

#Preview("small", as: .systemSmall) {
    FrameOfTheDayWidget()
} timeline: {
    FrameOfTheDayEntry.sample
    FrameOfTheDayEntry.placeholder
    FrameOfTheDayEntry.sampleFailure
}

#Preview("medium", as: .systemMedium) {
    FrameOfTheDayWidget()
} timeline: {
    FrameOfTheDayEntry.sample
    FrameOfTheDayEntry.sampleFailure
}

#Preview("large", as: .systemLarge) {
    FrameOfTheDayWidget()
} timeline: {
    FrameOfTheDayEntry.sample
    FrameOfTheDayEntry.placeholder
}

#Preview("extra large", as: .systemExtraLarge) {
    FrameOfTheDayWidget()
} timeline: {
    FrameOfTheDayEntry.sample
}
#endif

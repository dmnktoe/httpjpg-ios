#if DEBUG
import SwiftUI
import WidgetKit

extension FrameOfTheDayEntry {
    static let sample = FrameOfTheDayEntry(
        date: Date(timeIntervalSince1970: 0),
        image: WidgetPreviewSample.artwork(seed: 3, size: CGSize(width: 900, height: 900))
    )

    static let sampleMusic = FrameOfTheDayEntry(
        date: Date(timeIntervalSince1970: 0),
        image: WidgetPreviewSample.artwork(seed: 1, size: CGSize(width: 240, height: 240)),
        content: .music(
            title: "mega mashup",
            artist: "te3shay",
            playURL: URL(string: "httpjpg://play/preview?title=mega%20mashup&src=https://example.com/mashup.wav"),
            listenURL: nil
        )
    )

    static let sampleVideo = FrameOfTheDayEntry(
        date: Date(timeIntervalSince1970: 0),
        image: WidgetPreviewSample.artwork(seed: 5, size: CGSize(width: 900, height: 500)),
        content: .video(caption: "blence live on display")
    )

    static let sampleFailure = FrameOfTheDayEntry.failure("no frames published")
}

#Preview("small", as: .systemSmall) {
    FrameOfTheDayWidget()
} timeline: {
    FrameOfTheDayEntry.sample
    FrameOfTheDayEntry.sampleMusic
    FrameOfTheDayEntry.placeholder
    FrameOfTheDayEntry.sampleFailure
}

#Preview("medium", as: .systemMedium) {
    FrameOfTheDayWidget()
} timeline: {
    FrameOfTheDayEntry.sample
    FrameOfTheDayEntry.sampleMusic
    FrameOfTheDayEntry.sampleVideo
    FrameOfTheDayEntry.sampleFailure
}

#Preview("large", as: .systemLarge) {
    FrameOfTheDayWidget()
} timeline: {
    FrameOfTheDayEntry.sample
    FrameOfTheDayEntry.sampleMusic
    FrameOfTheDayEntry.placeholder
}

#Preview("extra large", as: .systemExtraLarge) {
    FrameOfTheDayWidget()
} timeline: {
    FrameOfTheDayEntry.sample
    FrameOfTheDayEntry.sampleVideo
}
#endif

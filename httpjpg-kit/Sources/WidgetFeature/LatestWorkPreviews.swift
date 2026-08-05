#if DEBUG
import StoryblokContent
import SwiftUI
import UIKit
import WidgetKit

extension LatestWorkEntry {
    static let sample: LatestWorkEntry = {
        let items = Array(WidgetPreviewSample.items.prefix(7))
        return LatestWorkEntry(
            date: Date(timeIntervalSince1970: 0),
            items: items,
            image: WidgetPreviewSample.artwork(seed: 0, size: CGSize(width: 720, height: 720)),
            thumbnails: WidgetPreviewSample.artwork(
                for: Array(items.dropFirst()),
                size: CGSize(width: 380, height: 220)
            )
        )
    }()

    static let sampleWithoutArtwork = LatestWorkEntry(
        date: Date(timeIntervalSince1970: 0),
        items: Array(WidgetPreviewSample.items.prefix(7))
    )

    static let sampleFailure = LatestWorkEntry.failure("STORYBLOK_ACCESS_TOKEN is missing")
}

#Preview("small", as: .systemSmall) {
    LatestWorkWidget()
} timeline: {
    LatestWorkEntry.sample
    LatestWorkEntry.sampleWithoutArtwork
    LatestWorkEntry.placeholder
}

#Preview("medium", as: .systemMedium) {
    LatestWorkWidget()
} timeline: {
    LatestWorkEntry.sample
    LatestWorkEntry.sampleWithoutArtwork
    LatestWorkEntry.placeholder
    LatestWorkEntry.sampleFailure
}

#Preview("large", as: .systemLarge) {
    LatestWorkWidget()
} timeline: {
    LatestWorkEntry.sample
    LatestWorkEntry.sampleWithoutArtwork
    LatestWorkEntry.placeholder
    LatestWorkEntry.sampleFailure
}

#Preview("extra large", as: .systemExtraLarge) {
    LatestWorkWidget()
} timeline: {
    LatestWorkEntry.sample
    LatestWorkEntry.sampleWithoutArtwork
    LatestWorkEntry.placeholder
    LatestWorkEntry.sampleFailure
}

#Preview("inline", as: .accessoryInline) {
    LatestWorkWidget()
} timeline: {
    LatestWorkEntry.sample
    LatestWorkEntry.placeholder
}

#Preview("rectangular", as: .accessoryRectangular) {
    LatestWorkWidget()
} timeline: {
    LatestWorkEntry.sample
    LatestWorkEntry.placeholder
}

#Preview("circular", as: .accessoryCircular) {
    LatestWorkWidget()
} timeline: {
    LatestWorkEntry.sample
    LatestWorkEntry.placeholder
}
#endif

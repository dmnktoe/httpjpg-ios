#if DEBUG
import SwiftUI
import WidgetKit

extension WorkGridEntry {
    static let sample: WorkGridEntry = {
        let items = WidgetPreviewSample.items
        return WorkGridEntry(
            date: Date(timeIntervalSince1970: 0),
            items: items,
            frames: WidgetPreviewSample.artwork(for: items, size: CGSize(width: 220, height: 220))
        )
    }()

    static let sampleWithoutArtwork = WorkGridEntry(
        date: Date(timeIntervalSince1970: 0),
        items: WidgetPreviewSample.items
    )

    static let sampleFailure = WorkGridEntry.failure("STORYBLOK_ACCESS_TOKEN is missing")
}

#Preview("medium", as: .systemMedium) {
    WorkGridWidget()
} timeline: {
    WorkGridEntry.sample
    WorkGridEntry.sampleWithoutArtwork
    WorkGridEntry.placeholder
    WorkGridEntry.sampleFailure
}

#Preview("large", as: .systemLarge) {
    WorkGridWidget()
} timeline: {
    WorkGridEntry.sample
    WorkGridEntry.sampleWithoutArtwork
    WorkGridEntry.sampleFailure
}

#Preview("extra large", as: .systemExtraLarge) {
    WorkGridWidget()
} timeline: {
    WorkGridEntry.sample
    WorkGridEntry.placeholder
}
#endif

#if DEBUG
import SwiftUI
import WidgetKit

extension ContactSheetEntry {
    static let sample: ContactSheetEntry = {
        let items = WidgetPreviewSample.items
        return ContactSheetEntry(
            date: Date(timeIntervalSince1970: 0),
            items: items,
            frames: WidgetPreviewSample.artwork(for: items, size: CGSize(width: 220, height: 220))
        )
    }()

    static let sampleWithoutArtwork = ContactSheetEntry(
        date: Date(timeIntervalSince1970: 0),
        items: WidgetPreviewSample.items
    )

    static let sampleFailure = ContactSheetEntry.failure("STORYBLOK_ACCESS_TOKEN is missing")
}

#Preview("medium", as: .systemMedium) {
    ContactSheetWidget()
} timeline: {
    ContactSheetEntry.sample
    ContactSheetEntry.sampleWithoutArtwork
    ContactSheetEntry.placeholder
    ContactSheetEntry.sampleFailure
}

#Preview("large", as: .systemLarge) {
    ContactSheetWidget()
} timeline: {
    ContactSheetEntry.sample
    ContactSheetEntry.sampleWithoutArtwork
    ContactSheetEntry.sampleFailure
}

#Preview("extra large", as: .systemExtraLarge) {
    ContactSheetWidget()
} timeline: {
    ContactSheetEntry.sample
    ContactSheetEntry.placeholder
}
#endif

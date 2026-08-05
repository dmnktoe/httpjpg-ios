#if DEBUG
import SwiftUI
import WidgetKit

extension WorkCountEntry {
    static let sample = WorkCountEntry(
        date: Date(timeIntervalSince1970: 0),
        projects: 28,
        websites: 14,
        firstYear: 2017,
        latestYear: 2026
    )

    static let sampleFirstYear = WorkCountEntry(
        date: Date(timeIntervalSince1970: 0),
        projects: 3,
        websites: 0,
        firstYear: 2026,
        latestYear: 2026
    )

    static let sampleFailure = WorkCountEntry.failure("STORYBLOK_ACCESS_TOKEN is missing")
}

#Preview("small", as: .systemSmall) {
    WorkCountWidget()
} timeline: {
    WorkCountEntry.sample
    WorkCountEntry.sampleFirstYear
    WorkCountEntry.sampleFailure
}

#Preview("inline", as: .accessoryInline) {
    WorkCountWidget()
} timeline: {
    WorkCountEntry.sample
}

#Preview("rectangular", as: .accessoryRectangular) {
    WorkCountWidget()
} timeline: {
    WorkCountEntry.sample
    WorkCountEntry.sampleFirstYear
}

#Preview("circular", as: .accessoryCircular) {
    WorkCountWidget()
} timeline: {
    WorkCountEntry.sample
}
#endif

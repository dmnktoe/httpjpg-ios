#if DEBUG
import StoryblokContent
import SwiftUI
import WidgetKit

extension SiteStatusEntry {
    // The status types are decode-only, so the samples go through the same JSON path
    // the site's endpoints do.
    static let sample = SiteStatusEntry(
        date: Date(timeIntervalSince1970: 0),
        discord: decodeSample(#"{"status": "online", "activity": "Xcode — httpjpg-ios"}"#),
        film: decodeSample(#"{"title": "Chungking Express", "year": "1994", "rating": 4.5, "liked": true}"#),
        trophy: decodeSample(#"{"name": "Nachtfahrt", "game": "Death Stranding", "type": "gold"}"#),
        weather: decodeSample(#"{"temperature": 18.4, "emoji": "🌤", "condition": "bewölkt"}"#)
    )

    static let sampleQuiet = SiteStatusEntry(
        date: Date(timeIntervalSince1970: 0),
        discord: decodeSample(#"{"status": "offline"}"#),
        weather: decodeSample(#"{"temperature": 3.0, "emoji": "🌧", "condition": "Regen"}"#)
    )

    static let sampleFailure = SiteStatusEntry.failure("nothing to report")

    private static func decodeSample<T: Decodable>(_ json: String) -> T? {
        try? JSONDecoder().decode(T.self, from: Data(json.utf8))
    }
}

#Preview("small", as: .systemSmall) {
    SiteStatusWidget()
} timeline: {
    SiteStatusEntry.sample
    SiteStatusEntry.sampleQuiet
    SiteStatusEntry.sampleFailure
}

#Preview("medium", as: .systemMedium) {
    SiteStatusWidget()
} timeline: {
    SiteStatusEntry.sample
    SiteStatusEntry.sampleQuiet
    SiteStatusEntry.placeholder
}

#Preview("rectangular", as: .accessoryRectangular) {
    SiteStatusWidget()
} timeline: {
    SiteStatusEntry.sample
    SiteStatusEntry.sampleQuiet
}

#Preview("inline", as: .accessoryInline) {
    SiteStatusWidget()
} timeline: {
    SiteStatusEntry.sample
    SiteStatusEntry.sampleQuiet
}
#endif

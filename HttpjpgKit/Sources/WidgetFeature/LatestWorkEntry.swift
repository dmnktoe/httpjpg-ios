import StoryblokContent
import UIKit
import WidgetKit

/// One rendering of the widget.
///
/// Widgets get no chance to load anything while they draw, so everything the
/// view needs — including the decoded image — has to be resolved by the
/// timeline provider and carried in here.
struct LatestWorkEntry: TimelineEntry {
    let date: Date
    /// Newest first. The featured entry is `items.first`.
    let items: [WorkItem]
    /// The featured entry's artwork, already downloaded and decoded.
    let image: UIImage?
    /// Set when the fetch failed, so the widget can say so instead of
    /// pretending the portfolio is empty.
    let message: String?

    var featured: WorkItem? { items.first }

    init(date: Date, items: [WorkItem], image: UIImage? = nil, message: String? = nil) {
        self.date = date
        self.items = items
        self.image = image
        self.message = message
    }

    /// Shown in the widget gallery and while the real timeline loads. Kept
    /// text-only so the gallery never shows a stale or half-loaded photo.
    static let placeholder = LatestWorkEntry(
        date: Date(timeIntervalSince1970: 0),
        items: [
            WorkItem(
                id: "placeholder",
                slug: "loading",
                fullSlug: "work/loading",
                title: "we're yet to find out",
                thumbnailURL: nil,
                imageFilenames: [],
                isDraft: false,
                isExternal: false,
                externalURL: nil,
                date: Date(timeIntervalSince1970: 0),
                tags: ["Projects"]
            ),
        ]
    )

    static func failure(_ message: String) -> LatestWorkEntry {
        LatestWorkEntry(date: Date(timeIntervalSince1970: 0), items: [], message: message)
    }
}

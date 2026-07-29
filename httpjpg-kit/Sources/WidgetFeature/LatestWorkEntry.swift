import StoryblokContent
import UIKit
import WidgetKit

struct LatestWorkEntry: TimelineEntry {
    let date: Date

    let items: [WorkItem]

    let image: UIImage?

    let message: String?

    var featured: WorkItem? { items.first }

    init(date: Date, items: [WorkItem], image: UIImage? = nil, message: String? = nil) {
        self.date = date
        self.items = items
        self.image = image
        self.message = message
    }

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

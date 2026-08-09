import StoryblokCore
import UIKit
import WidgetKit

struct LatestWorkEntry: TimelineEntry {
    let date: Date

    let items: [WorkItem]

    let image: UIImage?

    let thumbnails: [String: UIImage]

    let message: String?

    var featured: WorkItem? { items.first }

    init(
        date: Date,
        items: [WorkItem],
        image: UIImage? = nil,
        thumbnails: [String: UIImage] = [:],
        message: String? = nil
    ) {
        self.date = date
        self.items = items
        self.image = image
        self.thumbnails = thumbnails
        self.message = message
    }

    static let placeholder = LatestWorkEntry(
        date: Date(timeIntervalSince1970: 0),
        items: [
            "we're yet to find out",
            "still in the darkroom",
            "tape rewinding",
            "loading the index",
            "no signal yet",
            "check back shortly",
            "almost there",
        ].enumerated().map { position, title in
            WorkItem(
                id: "placeholder-\(position)",
                slug: "loading-\(position)",
                fullSlug: "work/loading-\(position)",
                title: title,
                thumbnailURL: nil,
                imageFilenames: [],
                isDraft: false,
                isExternal: false,
                externalURL: nil,
                date: nil,
                tags: ["Projects"]
            )
        }
    )

    static func failure(_ message: String) -> LatestWorkEntry {
        LatestWorkEntry(date: Date(timeIntervalSince1970: 0), items: [], message: message)
    }
}

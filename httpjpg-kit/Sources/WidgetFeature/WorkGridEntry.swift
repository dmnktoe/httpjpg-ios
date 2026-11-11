import StoryblokCore
import UIKit
import WidgetKit

struct WorkGridEntry: TimelineEntry {
    let date: Date

    let items: [WorkItem]

    let frames: [String: UIImage]

    let message: String?

    init(
        date: Date,
        items: [WorkItem],
        frames: [String: UIImage] = [:],
        message: String? = nil
    ) {
        self.date = date
        self.items = items
        self.frames = frames
        self.message = message
    }

    static let placeholder = WorkGridEntry(
        date: Date(timeIntervalSince1970: 0),
        items: (0 ..< WorkGridLayout.maximumTiles).map { position in
            WorkItem(
                id: "placeholder-\(position)",
                slug: "loading-\(position)",
                fullSlug: "work/loading-\(position)",
                title: "…",
                thumbnailURL: nil,
                imageFilenames: [],
                isDraft: false,
                isExternal: false,
                externalURL: nil,
                date: nil,
                sliceTags: ["Projects"]
            )
        }
    )

    static func failure(_ message: String) -> WorkGridEntry {
        WorkGridEntry(date: Date(timeIntervalSince1970: 0), items: [], message: message)
    }
}

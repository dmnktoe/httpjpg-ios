import Foundation

public struct AdjacentWorkItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let slug: String
    public let title: String

    public init(item: WorkItem) {
        id = item.id
        slug = item.slug
        title = item.title
    }
}

public enum AdjacentWork {
    /// Prev/next neighbours in the work index, sorted by date descending like the web.
    public static func neighbours(
        for slug: String,
        in items: [WorkItem]
    ) -> (prev: AdjacentWorkItem?, next: AdjacentWorkItem?) {
        let ordered = items
            .filter { !$0.isDraft }
            .sorted { lhs, rhs in
                switch (lhs.date, rhs.date) {
                case let (l?, r?): return l > r
                case (nil, _?): return false
                case (_?, nil): return true
                case (nil, nil): return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }
            }

        guard let index = ordered.firstIndex(where: { $0.slug == slug }) else {
            return (nil, nil)
        }

        let prev = index > 0 ? AdjacentWorkItem(item: ordered[index - 1]) : nil
        let next = index + 1 < ordered.count ? AdjacentWorkItem(item: ordered[index + 1]) : nil
        return (prev, next)
    }
}

import CoreSpotlight
import Foundation
import StoryblokCore
import UniformTypeIdentifiers

enum WorkSpotlightIndex {
    static let domain = "work"

    static func refresh(with collection: WorkCollection) {
        Task { await index(collection) }
    }

    /// Awaitable so a background refresh does not report itself finished while
    /// the index is still being written.
    static func index(_ collection: WorkCollection) async {
        var seen = Set<String>()
        let items = (collection.projects + collection.websites)
            .filter { seen.insert($0.slug).inserted }

        guard #available(iOS 18.0, *) else {
            return indexSearchableItems(items)
        }
        await indexAppEntities(items)
    }

    static func slug(from activity: NSUserActivity) -> String? {
        guard activity.activityType == CSSearchableItemActionType else { return nil }
        return activity.userInfo?[CSSearchableItemActivityIdentifier] as? String
    }

    @available(iOS 18.0, *)
    private static func indexAppEntities(_ items: [WorkItem]) async {
        let index = CSSearchableIndex.default()
        do {
            // An install that indexed under iOS 17 still carries the hand-rolled
            // items; leaving them behind would double every hit.
            try await index.deleteSearchableItems(withDomainIdentifiers: [domain])
            try await index.deleteAppEntities(ofType: WorkEntity.self)
            try await index.indexAppEntities(items.map(WorkEntity.init(item:)))
        } catch {
            // Spotlight is a nicety — a failed index is not worth surfacing.
        }
    }

    private static func indexSearchableItems(_ items: [WorkItem]) {
        let index = CSSearchableIndex.default()
        let searchable = items.map(searchableItem(for:))
        index.deleteSearchableItems(withDomainIdentifiers: [domain]) { _ in
            index.indexSearchableItems(searchable)
        }
    }

    private static func searchableItem(for item: WorkItem) -> CSSearchableItem {
        let attributes = CSSearchableItemAttributeSet(contentType: .content)
        attributes.title = item.title
        attributes.contentDescription = item.summary.isEmpty ? nil : item.summary
        attributes.keywords = item.tags
        attributes.contentModificationDate = item.date

        return CSSearchableItem(
            uniqueIdentifier: item.slug,
            domainIdentifier: domain,
            attributeSet: attributes
        )
    }
}

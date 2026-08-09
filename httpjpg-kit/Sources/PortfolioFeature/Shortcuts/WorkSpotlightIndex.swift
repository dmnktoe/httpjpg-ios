import CoreSpotlight
import Foundation
import StoryblokCore
import UniformTypeIdentifiers

enum WorkSpotlightIndex {
    static let domain = "work"

    static func refresh(with collection: WorkCollection) {
        let items = (collection.projects + collection.websites).map(searchableItem(for:))
        let index = CSSearchableIndex.default()
        index.deleteSearchableItems(withDomainIdentifiers: [domain]) { _ in
            index.indexSearchableItems(items)
        }
    }

    static func slug(from activity: NSUserActivity) -> String? {
        guard activity.activityType == CSSearchableItemActionType else { return nil }
        return activity.userInfo?[CSSearchableItemActivityIdentifier] as? String
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

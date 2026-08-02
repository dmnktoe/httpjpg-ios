import CoreSpotlight
import Foundation
import StoryblokContent
import UniformTypeIdentifiers

/// Puts every work into Spotlight, so searching the phone finds the portfolio
/// without opening the app first. Refreshed from the same place the home-screen
/// quick actions are, whenever the index loads.
enum WorkSpotlightIndex {
    static let domain = "work"

    static func refresh(with collection: WorkCollection) {
        let items = (collection.projects + collection.websites).map(searchableItem(for:))
        let index = CSSearchableIndex.default()
        // Replacing the whole domain rather than appending: a work unpublished
        // on the web should stop being findable here too.
        index.deleteSearchableItems(withDomainIdentifiers: [domain]) { _ in
            index.indexSearchableItems(items)
        }
    }

    /// The slug an activity came back with, or nil when it is not one of ours.
    static func slug(from activity: NSUserActivity) -> String? {
        guard activity.activityType == CSSearchableItemActionType else { return nil }
        return activity.userInfo?[CSSearchableItemActivityIdentifier] as? String
    }

    private static func searchableItem(for item: WorkItem) -> CSSearchableItem {
        let attributes = CSSearchableItemAttributeSet(contentType: .content)
        attributes.title = item.title
        attributes.contentDescription = item.summary.isEmpty ? nil : item.summary
        attributes.keywords = item.tags
        // No thumbnail: `thumbnailURL` has to be a local file, and the covers
        // live on Storyblok's CDN.
        attributes.contentModificationDate = item.date

        return CSSearchableItem(
            uniqueIdentifier: item.slug,
            domainIdentifier: domain,
            attributeSet: attributes
        )
    }
}

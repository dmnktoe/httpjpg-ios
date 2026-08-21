import AppIntents
import CoreSpotlight
import Foundation
import StoryblokCore

public struct WorkEntity: AppEntity, Sendable {
    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Work")
    }

    public static var defaultQuery: WorkEntityQuery { WorkEntityQuery() }

    public let id: String
    public let title: String
    public let summary: String
    public let keywords: [String]
    public let date: Date?

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: summary.isEmpty ? nil : "\(summary)"
        )
    }

    public init(
        id: String,
        title: String,
        summary: String = "",
        keywords: [String] = [],
        date: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.keywords = keywords
        self.date = date
    }

    init(item: WorkItem) {
        self.init(
            id: item.slug,
            title: item.title,
            summary: item.summary,
            keywords: item.tags,
            date: item.date
        )
    }
}

/// Hands Spotlight the entity itself rather than a parallel set of hand-rolled
/// searchable items: one index, and tapping a hit runs `OpenWorkIntent` with
/// the work already resolved.
@available(iOS 18.0, *)
extension WorkEntity: IndexedEntity {
    public var attributeSet: CSSearchableItemAttributeSet {
        let attributes = defaultAttributeSet
        attributes.title = title
        attributes.contentDescription = summary.isEmpty ? nil : summary
        attributes.keywords = keywords.isEmpty ? nil : keywords
        attributes.contentModificationDate = date
        return attributes
    }
}

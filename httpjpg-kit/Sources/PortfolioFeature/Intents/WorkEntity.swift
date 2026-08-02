import AppIntents
import StoryblokContent

/// A single work, as Siri and the Shortcuts app see it. The slug is the id
/// because that is what every other entry point into the app already routes on.
public struct WorkEntity: AppEntity, Sendable {
    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Work")
    }

    public static var defaultQuery: WorkEntityQuery { WorkEntityQuery() }

    public let id: String
    public let title: String
    public let summary: String

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: summary.isEmpty ? nil : "\(summary)"
        )
    }

    public init(id: String, title: String, summary: String = "") {
        self.id = id
        self.title = title
        self.summary = summary
    }

    init(item: WorkItem) {
        self.init(id: item.slug, title: item.title, summary: item.summary)
    }
}

import AppIntents
import StoryblokCore

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

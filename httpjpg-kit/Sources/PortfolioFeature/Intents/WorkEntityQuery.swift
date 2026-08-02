import AppIntents
import StoryblokContent

public struct WorkEntityQuery: EntityStringQuery, Sendable {
    public init() {}

    public func entities(for identifiers: [String]) async throws -> [WorkEntity] {
        let wanted = Set(identifiers)
        return try await all().filter { wanted.contains($0.id) }
    }

    public func entities(matching string: String) async throws -> [WorkEntity] {
        let needle = string.lowercased()
        guard !needle.isEmpty else { return try await suggestedEntities() }
        return try await all().filter { $0.title.lowercased().contains(needle) }
    }

    public func suggestedEntities() async throws -> [WorkEntity] {
        try await all()
    }

    private func all() async throws -> [WorkEntity] {
        let configuration = try StoryblokConfiguration.fromBundle()
        let collection = try await ContentClient(configuration: configuration).workIndex()
        return (collection.projects + collection.websites).map(WorkEntity.init(item:))
    }
}

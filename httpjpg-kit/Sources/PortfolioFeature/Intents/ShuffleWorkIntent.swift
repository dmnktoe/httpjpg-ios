import AppIntents
import StoryblokCore

public struct ShuffleWorkIntent: AppIntent {
    public static var title: LocalizedStringResource { "Shuffle Work" }

    public static var description: IntentDescription {
        IntentDescription("Opens a work at random from the httpjpg portfolio.")
    }

    public static var openAppWhenRun: Bool { true }

    public init() {}

    public func perform() async throws -> some IntentResult {
        let configuration = try StoryblokConfiguration.fromBundle()
        let collection = try await ContentClient(configuration: configuration).workIndex()
        let pool = (collection.projects + collection.websites).map(\.slug)
        guard !pool.isEmpty else { return .result() }

        await MainActor.run {
            QuickActionInbox.shared.post(.shuffle(pool: pool))
        }
        return .result()
    }
}

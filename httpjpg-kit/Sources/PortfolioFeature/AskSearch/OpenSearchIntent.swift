import AppIntents

/// Opens the Ask · Search palette, optionally prefilled — the Shortcuts / Siri entry.
public struct OpenSearchIntent: AppIntent {
    public static var title: LocalizedStringResource { "Search Portfolio" }

    public static var description: IntentDescription {
        IntentDescription("Opens search and ask in the httpjpg portfolio.")
    }

    public static var openAppWhenRun: Bool { true }

    @Parameter(title: "Query")
    public var query: String?

    public init() {}

    public init(query: String?) {
        self.query = query
    }

    public static var parameterSummary: some ParameterSummary {
        Summary("Search \(\.$query) in httpjpg")
    }

    @MainActor
    public func perform() async throws -> some IntentResult {
        let trimmed = query?.trimmingCharacters(in: .whitespacesAndNewlines)
        QuickActionInbox.shared.post(.search(query: trimmed?.isEmpty == false ? trimmed : nil))
        return .result()
    }
}

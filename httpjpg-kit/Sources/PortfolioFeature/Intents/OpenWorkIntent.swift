import AppIntents

public struct OpenWorkIntent: AppIntent {
    public static var title: LocalizedStringResource { "Open Work" }

    public static var description: IntentDescription {
        IntentDescription("Opens a work from the httpjpg portfolio.")
    }

    public static var openAppWhenRun: Bool { true }

    @Parameter(title: "Work")
    public var work: WorkEntity

    public init() {}

    public static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$work)")
    }

    @MainActor
    public func perform() async throws -> some IntentResult {
        // The app may still be launching. RootView drains the inbox on appear
        // and watches it afterwards, so either order lands on the work.
        QuickActionInbox.shared.post(.work(slug: work.id, title: work.title))
        return .result()
    }
}

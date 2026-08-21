import AppIntents

/// An `OpenIntent` rather than a plain `AppIntent`: Spotlight fills `target`
/// with the entity someone tapped, so the indexed work routes straight here.
public struct OpenWorkIntent: OpenIntent {
    public static var title: LocalizedStringResource { "Open Work" }

    public static var description: IntentDescription {
        IntentDescription("Opens a work from the httpjpg portfolio.")
    }

    public static var openAppWhenRun: Bool { true }

    @Parameter(title: "Work")
    public var target: WorkEntity

    public init() {}

    public init(target: WorkEntity) {
        self.target = target
    }

    public static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$target)")
    }

    @MainActor
    public func perform() async throws -> some IntentResult {
        QuickActionInbox.shared.post(.work(slug: target.id, title: target.title))
        return .result()
    }
}

import AppIntents
import PortfolioFeature

/// Lives in the app target rather than in `PortfolioFeature`: App Intents
/// metadata extraction runs against the app, and a provider tucked away in a
/// package is not reliably picked up.
struct HttpjpgShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenWorkIntent(),
            phrases: [
                "Open a work in \(.applicationName)",
                "Show me a work in \(.applicationName)",
            ],
            shortTitle: "Open Work",
            systemImageName: "photo.on.rectangle.angled"
        )

        AppShortcut(
            intent: ShuffleWorkIntent(),
            phrases: [
                "Shuffle \(.applicationName)",
                "Surprise me in \(.applicationName)",
            ],
            shortTitle: "Shuffle Work",
            systemImageName: "shuffle"
        )
    }
}

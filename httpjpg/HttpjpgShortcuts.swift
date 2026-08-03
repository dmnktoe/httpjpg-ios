import AppIntents
import PortfolioFeature

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

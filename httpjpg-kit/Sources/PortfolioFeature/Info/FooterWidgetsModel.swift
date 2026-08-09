import Foundation
import Observation
import StoryblokContent

@MainActor
@Observable
final class FooterWidgetsModel {
    private let api: SiteAPI
    private let flags: WidgetFlags

    private(set) var discord: DiscordPresence?
    private(set) var film: LetterboxdFilm?
    private(set) var trophy: PsnTrophy?
    private(set) var weather: WeatherNow?

    private(set) var isLoaded = false

    init(origin: URL, flags: WidgetFlags) {
        self.api = SiteAPI(origin: origin)
        self.flags = flags
    }

    func load() async {
        async let presence = loadDiscord()
        async let latestFilm = loadFilm()
        async let latestTrophy = loadTrophy()
        async let now = api.weather()
        let (loadedPresence, loadedFilm, loadedTrophy, loadedWeather) =
            await (presence, latestFilm, latestTrophy, now)

        discord = loadedPresence
        film = loadedFilm
        trophy = loadedTrophy
        weather = loadedWeather
        isLoaded = true
    }

    private func loadDiscord() async -> DiscordPresence? {
        guard flags.isDiscordEnabled else { return nil }
        return await api.discordPresence()
    }

    private func loadFilm() async -> LetterboxdFilm? {
        guard flags.isLetterboxdEnabled else { return nil }
        return await api.latestFilm()
    }

    private func loadTrophy() async -> PsnTrophy? {
        guard flags.isPsnTrophyEnabled else { return nil }
        return await api.latestTrophy()
    }
}

import StoryblokContent
import WidgetKit

struct SiteStatusEntry: TimelineEntry {
    let date: Date

    let discord: DiscordPresence?
    let film: LetterboxdFilm?
    let trophy: PsnTrophy?
    let weather: WeatherNow?

    let message: String?

    init(
        date: Date,
        discord: DiscordPresence? = nil,
        film: LetterboxdFilm? = nil,
        trophy: PsnTrophy? = nil,
        weather: WeatherNow? = nil,
        message: String? = nil
    ) {
        self.date = date
        self.discord = discord
        self.film = film
        self.trophy = trophy
        self.weather = weather
        self.message = message
    }

    var lines: [SiteStatusLine] {
        [
            discord.map(SiteStatusLine.init(discord:)),
            film.flatMap(SiteStatusLine.init(film:)),
            trophy.flatMap(SiteStatusLine.init(trophy:)),
            weather.flatMap(SiteStatusLine.init(weather:)),
        ].compactMap { $0 }
    }

    static let placeholder = SiteStatusEntry(date: Date(timeIntervalSince1970: 0))

    static func failure(_ message: String) -> SiteStatusEntry {
        SiteStatusEntry(date: Date(timeIntervalSince1970: 0), message: message)
    }
}

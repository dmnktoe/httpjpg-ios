import Foundation
import Observation
import StoryblokCore

@MainActor
@Observable
final class FooterWidgetsModel {
    private let api: SiteAPI

    /// Read by the view too, so a widget switched off holds no loading row.
    let flags: WidgetFlags

    private(set) var discord: DiscordPresence?
    private(set) var film: LetterboxdFilm?
    private(set) var record: DiscogsRelease?
    private(set) var timeline: XTimeline?
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
        async let latestRecord = loadRecord()
        async let latestTimeline = loadTimeline()
        async let latestTrophy = loadTrophy()
        async let now = api.weather()
        let (loadedPresence, loadedFilm, loadedRecord, loadedTimeline, loadedTrophy, loadedWeather) =
            await (presence, latestFilm, latestRecord, latestTimeline, latestTrophy, now)

        discord = loadedPresence
        film = loadedFilm
        record = loadedRecord
        timeline = loadedTimeline
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

    private func loadRecord() async -> DiscogsRelease? {
        guard flags.isDiscogsEnabled else { return nil }
        return await api.latestRecord()
    }

    private func loadTimeline() async -> XTimeline? {
        guard flags.isXEnabled else { return nil }
        return await api.xTimeline()
    }

    private func loadTrophy() async -> PsnTrophy? {
        guard flags.isPsnTrophyEnabled else { return nil }
        return await api.latestTrophy()
    }
}

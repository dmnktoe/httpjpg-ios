import Foundation
import Observation
import StoryblokCore

@MainActor
@Observable
final class FooterWidgetsModel {
    private let api: SiteAPI

    let flags: WidgetFlags

    private(set) var discord: DiscordPresence?
    private(set) var film: LetterboxdFilm?
    private(set) var record: DiscogsRelease?
    private(set) var scrobbles: LastfmScrobbles?
    private(set) var steam: SteamStatus?
    private(set) var youtube: YoutubeStatus?
    private(set) var github: GithubStatus?
    private(set) var timeline: XTimeline?
    private(set) var trophy: PsnTrophy?
    private(set) var schalke: SchalkeStatus?
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
        async let latestSchalke = loadSchalke()
        async let latestScrobbles = loadScrobbles()
        async let latestSteam = loadSteam()
        async let latestYoutube = loadYoutube()
        async let latestGithub = loadGithub()
        async let now = api.weather()
        let (loadedPresence, loadedFilm, loadedRecord, loadedTimeline, loadedTrophy, loadedWeather) =
            await (presence, latestFilm, latestRecord, latestTimeline, latestTrophy, now)
        let loadedSchalke = await latestSchalke
        let (loadedScrobbles, loadedSteam, loadedYoutube, loadedGithub) =
            await (latestScrobbles, latestSteam, latestYoutube, latestGithub)

        discord = loadedPresence
        film = loadedFilm
        record = loadedRecord
        scrobbles = loadedScrobbles
        steam = loadedSteam
        youtube = loadedYoutube
        github = loadedGithub
        timeline = loadedTimeline
        trophy = loadedTrophy
        schalke = loadedSchalke
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

    private func loadScrobbles() async -> LastfmScrobbles? {
        guard flags.isLastfmEnabled else { return nil }
        return await api.lastfmScrobbles()
    }

    private func loadSteam() async -> SteamStatus? {
        guard flags.isSteamEnabled else { return nil }
        return await api.steamStatus()
    }

    private func loadYoutube() async -> YoutubeStatus? {
        guard flags.isYoutubeEnabled else { return nil }
        return await api.youtubeStatus()
    }

    private func loadGithub() async -> GithubStatus? {
        guard flags.isGithubEnabled else { return nil }
        return await api.githubStatus()
    }

    private func loadTimeline() async -> XTimeline? {
        guard flags.isXEnabled else { return nil }
        return await api.xTimeline()
    }

    private func loadTrophy() async -> PsnTrophy? {
        guard flags.isPsnTrophyEnabled else { return nil }
        return await api.latestTrophy()
    }

    private func loadSchalke() async -> SchalkeStatus? {
        guard flags.isSchalkeEnabled else { return nil }
        return await api.schalkeStatus()
    }
}

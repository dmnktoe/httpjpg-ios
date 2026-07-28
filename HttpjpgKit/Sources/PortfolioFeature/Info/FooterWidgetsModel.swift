import Foundation
import Observation
import StoryblokContent

/// Loads the four live status lines the site's footer carries.
///
/// Each one is independent and each one is allowed to come back empty: a widget
/// with nothing to say renders nothing, exactly as it does on the web, rather
/// than holding a "loading" row forever.
///
/// The server-side flags gate the *requests*, not just the rows. A disabled
/// widget never hits the network, which is the difference between honouring a
/// switch and merely hiding its output.
@MainActor
@Observable
final class FooterWidgetsModel {
    private let api: SiteAPI
    private let flags: WidgetFlags

    private(set) var discord: DiscordPresence?
    private(set) var film: LetterboxdFilm?
    private(set) var trophy: PsnTrophy?
    private(set) var weather: WeatherNow?

    init(origin: URL, flags: WidgetFlags) {
        self.api = SiteAPI(origin: origin)
        self.flags = flags
    }

    /// `true` once there is at least one line worth a divider above it.
    var hasContent: Bool {
        discord != nil || film != nil || trophy != nil || weather != nil || isClockShown
    }

    /// The clock needs no network and no flag — it is the device's own time.
    var isClockShown: Bool { true }

    func load() async {
        // Concurrently, because four sequential round trips to four unrelated
        // services is three round trips of dead time.
        async let presence = loadDiscord()
        async let latestFilm = loadFilm()
        async let latestTrophy = loadTrophy()
        async let now = api.weather()

        discord = await presence
        film = await latestFilm
        trophy = await latestTrophy
        weather = await now
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
        guard flags.isTrophyEnabled else { return nil }
        return await api.latestTrophy()
    }
}

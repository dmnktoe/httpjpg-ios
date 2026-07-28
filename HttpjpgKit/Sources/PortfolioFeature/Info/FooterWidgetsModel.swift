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

    func load() async {
        // Concurrently, because four sequential round trips to four unrelated
        // services is three round trips of dead time — but assigned in one
        // batch at the end. Assigning each result as its await settled gave
        // the footer up to four height changes in quick succession, and a
        // footer with a cover background visibly flickers every time it
        // resizes.
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
    }

    private func loadDiscord() async -> DiscordPresence? {
        guard flags.isDiscordEnabled else { return nil }
        return await api.discordPresence()
    }

    private func loadFilm() async -> LetterboxdFilm? {
        guard flags.isLetterboxdEnabled else { return nil }
        return await api.latestFilm()
    }

    /// No flag gate: the web footer renders `TrophyStatus` unconditionally —
    /// `psn_enabled` belongs to the PSN card elsewhere on the site — and the
    /// endpoint self-gates by erroring when the server has no PSN credentials,
    /// which comes back as `nil` and an absent row.
    private func loadTrophy() async -> PsnTrophy? {
        await api.latestTrophy()
    }
}

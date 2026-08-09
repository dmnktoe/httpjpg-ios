import Foundation
import StoryblokCore
import WidgetKit

struct SiteStatusEntry: TimelineEntry {
    let date: Date

    let discord: DiscordPresence?
    let film: LetterboxdFilm?
    let record: DiscogsRelease?
    let timeline: XTimeline?
    let trophy: PsnTrophy?
    let weather: WeatherNow?

    let message: String?

    init(
        date: Date,
        discord: DiscordPresence? = nil,
        film: LetterboxdFilm? = nil,
        record: DiscogsRelease? = nil,
        timeline: XTimeline? = nil,
        trophy: PsnTrophy? = nil,
        weather: WeatherNow? = nil,
        message: String? = nil
    ) {
        self.date = date
        self.discord = discord
        self.film = film
        self.record = record
        self.timeline = timeline
        self.trophy = trophy
        self.weather = weather
        self.message = message
    }

    var lines: [SiteStatusLine] {
        [
            discord.map(SiteStatusLine.init(discord:)),
            film.flatMap(SiteStatusLine.init(film:)),
            record.flatMap(SiteStatusLine.init(record:)),
            post.flatMap { SiteStatusLine(profile: $0.profile, post: $0.post) },
            trophy.flatMap(SiteStatusLine.init(trophy:)),
            weather.flatMap(SiteStatusLine.init(weather:)),
        ].compactMap { $0 }
    }

    private var post: (profile: XProfile, post: XPost)? {
        guard let timeline, let latest = timeline.latestPost else { return nil }
        return (timeline.profile, latest)
    }

    static let placeholder = SiteStatusEntry(date: Date(timeIntervalSince1970: 0))

    static func failure(_ message: String) -> SiteStatusEntry {
        SiteStatusEntry(date: Date(timeIntervalSince1970: 0), message: message)
    }
}

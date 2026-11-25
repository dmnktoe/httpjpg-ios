import Foundation
import StoryblokCore
import WidgetKit

struct SiteStatusEntry: TimelineEntry {
    let date: Date

    let discord: DiscordPresence?
    let film: LetterboxdFilm?
    let record: DiscogsRelease?
    let scrobbles: LastfmScrobbles?
    let steam: SteamStatus?
    let youtube: YoutubeStatus?
    let github: GithubStatus?
    let reddit: RedditKarma?
    let timeline: XTimeline?
    let trophy: PsnTrophy?
    let schalke: SchalkeStatus?
    let weather: WeatherNow?

    let message: String?

    init(
        date: Date,
        discord: DiscordPresence? = nil,
        film: LetterboxdFilm? = nil,
        record: DiscogsRelease? = nil,
        scrobbles: LastfmScrobbles? = nil,
        steam: SteamStatus? = nil,
        youtube: YoutubeStatus? = nil,
        github: GithubStatus? = nil,
        reddit: RedditKarma? = nil,
        timeline: XTimeline? = nil,
        trophy: PsnTrophy? = nil,
        schalke: SchalkeStatus? = nil,
        weather: WeatherNow? = nil,
        message: String? = nil
    ) {
        self.date = date
        self.discord = discord
        self.film = film
        self.record = record
        self.scrobbles = scrobbles
        self.steam = steam
        self.youtube = youtube
        self.github = github
        self.reddit = reddit
        self.timeline = timeline
        self.trophy = trophy
        self.schalke = schalke
        self.weather = weather
        self.message = message
    }

    var lines: [SiteStatusLine] {
        let footerOrder = [
            discord.map(SiteStatusLine.init(discord:)),
            film.flatMap(SiteStatusLine.init(film:)),
            record.flatMap(SiteStatusLine.init(record:)),
            scrobbles.flatMap { SiteStatusLine(scrobbles: $0, now: date) },
            steam.flatMap { SiteStatusLine(steam: $0, now: date) },
            youtube.flatMap(SiteStatusLine.init(youtube:)),
            github.flatMap(SiteStatusLine.init(github:)),
            reddit.map(SiteStatusLine.init(reddit:)),
            post.flatMap { SiteStatusLine(profile: $0.profile, post: $0.post) },
            trophy.flatMap(SiteStatusLine.init(trophy:)),
            schalke.flatMap { SiteStatusLine(schalke: $0, now: date) },
            weather.flatMap(SiteStatusLine.init(weather:)),
        ].compactMap { $0 }

        return footerOrder.enumerated()
            .sorted { lhs, rhs in
                let (left, right) = (rank(lhs.element), rank(rhs.element))
                if left != right { return left < right }
                if let leftDate = lhs.element.date, let rightDate = rhs.element.date, leftDate != rightDate {
                    return leftDate > rightDate
                }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    private func rank(_ line: SiteStatusLine) -> Int {
        if line.id == "discord", let discord, discord.status != .offline { return 0 }
        return line.date == nil ? 2 : 1
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

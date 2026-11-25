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

        return StatusOrder.sorted(footerOrder, isLive: isLive, date: \.date)
    }

    private func isLive(_ line: SiteStatusLine) -> Bool {
        line.id == "discord" && discord.map { $0.status != .offline } == true
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

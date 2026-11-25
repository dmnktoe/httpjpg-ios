import Foundation
import StoryblokCore

/// One footer source as the watch shows it: the web's line, stacked to fit the
/// narrow screen, with the server's pixel art in front.
struct WatchStatusLine: Identifiable {
    let id: String
    let label: String
    let image: Data?
    let text: String
    let detail: String?

    struct Sources {
        var discord: DiscordPresence?
        var film: LetterboxdFilm?
        var record: DiscogsRelease?
        var scrobbles: LastfmScrobbles?
        var steam: SteamStatus?
        var youtube: YoutubeStatus?
        var github: GithubStatus?
        var reddit: RedditKarma?
        var timeline: XTimeline?
        var trophy: PsnTrophy?
        var schalke: SchalkeStatus?
        var weather: WeatherNow?
    }

    /// In the web footer's order; a source that is off or silent is left out.
    static func lines(from sources: Sources) -> [WatchStatusLine] {
        var lines: [WatchStatusLine] = []

        if let discord = sources.discord {
            lines.append(WatchStatusLine(
                id: "discord", label: "discord", image: nil,
                text: discord.status.rawValue, detail: discord.activity
            ))
        }
        if let film = sources.film, !film.title.isEmpty {
            let detail = [film.year, film.stars, film.liked ? "♥" : nil].compactMap { $0 }
            lines.append(WatchStatusLine(
                id: "letterboxd", label: "letterboxd", image: film.poster,
                text: film.title, detail: detail.isEmpty ? nil : detail.joined(separator: " ")
            ))
        }
        if let record = sources.record, !record.title.isEmpty {
            lines.append(WatchStatusLine(
                id: "discogs", label: "discogs", image: record.thumb,
                text: record.credit, detail: record.year
            ))
        }
        if let track = sources.scrobbles?.latest {
            let marks = [track.isNowPlaying ? "▶" : nil, track.isLoved ? "♥" : nil].compactMap { $0 }
            lines.append(WatchStatusLine(
                id: "lastfm", label: "last.fm", image: track.image,
                text: track.title, detail: ([track.artist] + marks).joined(separator: " ")
            ))
        }
        if let steam = sources.steam, let game = steam.featured {
            let detail = [steam.isPlaying ? "▶" : nil, game.recentPlaytime].compactMap { $0 }
            lines.append(WatchStatusLine(
                id: "steam", label: "steam", image: game.icon,
                text: game.name, detail: detail.isEmpty ? nil : detail.joined(separator: " ")
            ))
        }
        if let youtube = sources.youtube, let video = youtube.latestVideo {
            lines.append(WatchStatusLine(
                id: "youtube", label: "youtube", image: youtube.channel.avatar,
                text: video.title, detail: youtube.channel.compactSubscriberCount.map { "(\($0))" }
            ))
        }
        if let github = sources.github, let activity = github.latest {
            let detail = [activity.verb, activity.detail].compactMap { $0 }
            lines.append(WatchStatusLine(
                id: "github", label: "github", image: github.avatar,
                text: activity.repo, detail: detail.joined(separator: " ")
            ))
        }
        if let reddit = sources.reddit {
            lines.append(WatchStatusLine(
                id: "reddit", label: "reddit", image: nil,
                text: reddit.handle, detail: reddit.compactKarma
            ))
        }
        if let timeline = sources.timeline, let post = timeline.latestPost, !post.text.isEmpty {
            lines.append(WatchStatusLine(
                id: "x", label: "x", image: timeline.profile.avatar,
                text: post.text, detail: timeline.profile.compactFollowerCount.map { "(\($0))" }
            ))
        }
        if let trophy = sources.trophy, !trophy.name.isEmpty {
            lines.append(WatchStatusLine(
                id: "psn", label: "psn", image: trophy.image,
                text: trophy.name, detail: trophy.game.isEmpty ? nil : trophy.game
            ))
        }
        if let schalke = sources.schalke {
            let place = schalke.standing.map { "\($0.position)." }
            if let fixture = schalke.fixture {
                lines.append(WatchStatusLine(
                    id: "schalke", label: "s04", image: fixture.homeCrest,
                    text: fixture.score, detail: place
                ))
            } else if let upcoming = schalke.upcoming {
                let detail = [upcoming.kickoffLabel(), place].compactMap { $0 }
                lines.append(WatchStatusLine(
                    id: "schalke", label: "s04", image: upcoming.homeCrest,
                    text: upcoming.pairing, detail: detail.isEmpty ? nil : detail.joined(separator: " · ")
                ))
            } else if let place {
                lines.append(WatchStatusLine(id: "schalke", label: "s04", image: nil, text: place, detail: nil))
            }
        }
        if let weather = sources.weather, let temperature = weather.temperature {
            lines.append(WatchStatusLine(
                id: "weather", label: "weather", image: nil,
                text: [weather.emoji, "\(Int(temperature.rounded()))°"].compactMap { $0 }.joined(separator: " "),
                detail: weather.condition
            ))
        }

        return lines
    }

    static func load(client: ContentClient) async -> [WatchStatusLine] {
        let flags = await client.siteConfig().widgets
        let api = SiteAPI(origin: client.configuration.siteOrigin)

        async let discord = flags.isDiscordEnabled ? await api.discordPresence() : nil
        async let film = flags.isLetterboxdEnabled ? await api.latestFilm() : nil
        async let record = flags.isDiscogsEnabled ? await api.latestRecord() : nil
        async let scrobbles = flags.isLastfmEnabled ? await api.lastfmScrobbles() : nil
        async let steam = flags.isSteamEnabled ? await api.steamStatus() : nil
        async let youtube = flags.isYoutubeEnabled ? await api.youtubeStatus() : nil
        async let github = flags.isGithubEnabled ? await api.githubStatus() : nil
        async let timeline = flags.isXEnabled ? await api.xTimeline() : nil
        async let trophy = flags.isPsnTrophyEnabled ? await api.latestTrophy() : nil
        async let schalke = flags.isSchalkeEnabled ? await api.schalkeStatus() : nil
        async let weather = api.weather()

        return await lines(from: Sources(
            discord: discord,
            film: film,
            record: record,
            scrobbles: scrobbles,
            steam: steam,
            youtube: youtube,
            github: github,
            reddit: flags.reddit,
            timeline: timeline,
            trophy: trophy,
            schalke: schalke,
            weather: weather
        ))
    }
}

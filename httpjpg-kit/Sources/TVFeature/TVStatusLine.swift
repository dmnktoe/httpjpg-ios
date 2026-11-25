import Foundation
import StoryblokCore

struct TVStatusLine: Identifiable, Hashable {
    let id: String
    let text: String
    var isLive = false
    var date: Date?

    static func lines(
        discord: DiscordPresence?,
        film: LetterboxdFilm?,
        record: DiscogsRelease?,
        scrobbles: LastfmScrobbles? = nil,
        steam: SteamStatus? = nil,
        youtube: YoutubeStatus? = nil,
        github: GithubStatus? = nil,
        reddit: RedditKarma? = nil,
        trophy: PsnTrophy?,
        weather: WeatherNow?
    ) -> [TVStatusLine] {
        var lines: [TVStatusLine] = []

        if let discord {
            let detail = [discord.status.rawValue, discord.activity].compactMap { $0 }
            lines.append(TVStatusLine(
                id: "discord",
                text: "discord: " + detail.joined(separator: " · "),
                isLive: discord.status != .offline
            ))
        }
        if let film, !film.title.isEmpty {
            let detail = [film.title, film.year, film.stars].compactMap { $0 }
            lines.append(TVStatusLine(
                id: "letterboxd",
                text: "letterboxd: " + detail.joined(separator: " "),
                date: film.watchedDate
            ))
        }
        if let record, !record.title.isEmpty {
            lines.append(TVStatusLine(id: "discogs", text: "discogs: " + record.credit, date: record.addedAt))
        }
        if let track = scrobbles?.latest {
            let detail = [track.title, track.artist, track.isNowPlaying ? "▶" : nil].compactMap { $0 }
            lines.append(TVStatusLine(
                id: "lastfm",
                text: "last.fm: " + detail.joined(separator: " · "),
                isLive: track.isNowPlaying,
                date: track.scrobbledAt
            ))
        }
        if let steam, let line = steam.line {
            let title = line.game?.name ?? steam.name
            let name = line.kind == .playing ? "\(title) ▶" : title
            let detail = [name, line.detail].compactMap { $0 }
            lines.append(TVStatusLine(
                id: "steam",
                text: "steam: " + detail.joined(separator: " · "),
                isLive: line.kind == .playing,
                date: line.game?.lastPlayedAt
            ))
        }
        if let youtube, let video = youtube.latestVideo {
            let detail = [youtube.channel.compactSubscriberCount.map { "(\($0))" }, video.title].compactMap { $0 }
            lines.append(TVStatusLine(
                id: "youtube",
                text: "youtube: " + detail.joined(separator: " · "),
                date: video.publishedAt
            ))
        }
        if let activity = github?.latest {
            let detail = [activity.verb, activity.repo, activity.detail].compactMap { $0 }
            lines.append(TVStatusLine(
                id: "github",
                text: "github: " + detail.joined(separator: " "),
                date: activity.createdAt
            ))
        }
        if let reddit {
            lines.append(TVStatusLine(id: "reddit", text: "reddit: \(reddit.handle) · \(reddit.compactKarma)"))
        }
        if let trophy, !trophy.name.isEmpty {
            let detail = [trophy.name, trophy.game.isEmpty ? nil : trophy.game].compactMap { $0 }
            lines.append(TVStatusLine(
                id: "psn",
                text: "psn: " + detail.joined(separator: " · "),
                date: trophy.earnedAt
            ))
        }
        if let weather, let temperature = weather.temperature {
            let detail = ["\(Int(temperature.rounded()))°", weather.condition].compactMap { $0 }
            lines.append(TVStatusLine(id: "weather", text: "weather: " + detail.joined(separator: " ")))
        }

        return StatusOrder.sorted(lines, isLive: \.isLive, date: \.date)
    }

    static func load(client: ContentClient, origin: URL) async -> [TVStatusLine] {
        let flags = await client.siteConfig().widgets
        let api = SiteAPI(origin: origin)

        async let discord = flags.isDiscordEnabled ? await api.discordPresence() : nil
        async let film = flags.isLetterboxdEnabled ? await api.latestFilm() : nil
        async let record = flags.isDiscogsEnabled ? await api.latestRecord() : nil
        async let scrobbles = flags.isLastfmEnabled ? await api.lastfmScrobbles() : nil
        async let steam = flags.isSteamEnabled ? await api.steamStatus() : nil
        async let youtube = flags.isYoutubeEnabled ? await api.youtubeStatus() : nil
        async let github = flags.isGithubEnabled ? await api.githubStatus() : nil
        async let trophy = flags.isPsnTrophyEnabled ? await api.latestTrophy() : nil
        async let weather = api.weather()

        return await lines(
            discord: discord,
            film: film,
            record: record,
            scrobbles: scrobbles,
            steam: steam,
            youtube: youtube,
            github: github,
            reddit: flags.reddit,
            trophy: trophy,
            weather: weather
        )
    }
}

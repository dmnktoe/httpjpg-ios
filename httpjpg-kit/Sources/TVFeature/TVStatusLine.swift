import Foundation
import StoryblokCore

struct TVStatusLine: Identifiable, Hashable {
    let id: String
    let text: String

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
            lines.append(TVStatusLine(id: "discord", text: "discord: " + detail.joined(separator: " · ")))
        }
        if let film, !film.title.isEmpty {
            let detail = [film.title, film.year, film.stars].compactMap { $0 }
            lines.append(TVStatusLine(id: "letterboxd", text: "letterboxd: " + detail.joined(separator: " ")))
        }
        if let record, !record.title.isEmpty {
            lines.append(TVStatusLine(id: "discogs", text: "discogs: " + record.credit))
        }
        if let track = scrobbles?.latest {
            let detail = [track.title, track.artist, track.isNowPlaying ? "▶" : nil].compactMap { $0 }
            lines.append(TVStatusLine(id: "lastfm", text: "last.fm: " + detail.joined(separator: " · ")))
        }
        if let steam, let game = steam.featured {
            let name = steam.isPlaying ? "\(game.name) ▶" : game.name
            let detail = [name, game.recentPlaytime].compactMap { $0 }
            lines.append(TVStatusLine(id: "steam", text: "steam: " + detail.joined(separator: " · ")))
        }
        if let youtube, let video = youtube.latestVideo {
            let detail = [youtube.channel.compactSubscriberCount.map { "(\($0))" }, video.title].compactMap { $0 }
            lines.append(TVStatusLine(id: "youtube", text: "youtube: " + detail.joined(separator: " · ")))
        }
        if let activity = github?.latest {
            let detail = [activity.verb, activity.repo, activity.detail].compactMap { $0 }
            lines.append(TVStatusLine(id: "github", text: "github: " + detail.joined(separator: " ")))
        }
        if let reddit {
            lines.append(TVStatusLine(id: "reddit", text: "reddit: \(reddit.handle) · \(reddit.compactKarma)"))
        }
        if let trophy, !trophy.name.isEmpty {
            let detail = [trophy.name, trophy.game.isEmpty ? nil : trophy.game].compactMap { $0 }
            lines.append(TVStatusLine(id: "psn", text: "psn: " + detail.joined(separator: " · ")))
        }
        if let weather, let temperature = weather.temperature {
            let detail = ["\(Int(temperature.rounded()))°", weather.condition].compactMap { $0 }
            lines.append(TVStatusLine(id: "weather", text: "weather: " + detail.joined(separator: " ")))
        }

        return lines
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

import StoryblokCore

struct TVStatusLine: Identifiable, Hashable {
    let id: String
    let text: String

    static func lines(
        discord: DiscordPresence?,
        film: LetterboxdFilm?,
        record: DiscogsRelease?,
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
        async let trophy = flags.isPsnTrophyEnabled ? await api.latestTrophy() : nil
        async let weather = api.weather()

        return await lines(discord: discord, film: film, record: record, trophy: trophy, weather: weather)
    }
}

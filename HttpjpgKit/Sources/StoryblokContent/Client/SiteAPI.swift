import Foundation

public actor SiteAPI {
    private let origin: URL
    private let session: URLSession

    public init(origin: URL, session: URLSession = .shared) {
        self.origin = origin
        self.session = session
    }

    public func discordPresence() async -> DiscordPresence? {
        await get(DiscordPresence.self, path: "/api/discord")
    }

    public func latestFilm() async -> LetterboxdFilm? {
        await get(LetterboxdFilmsResponse.self, path: "/api/letterboxd")?.films.first
    }

    public func latestTrophy() async -> PsnTrophy? {
        await get(PsnTrophiesResponse.self, path: "/api/psn-trophies")?.trophies.first
    }

    public func weather() async -> WeatherNow? {
        await get(WeatherNow.self, path: "/api/weather")
    }

    private func get<T: Decodable>(_ type: T.Type, path: String) async -> T? {
        guard let url = URL(string: path, relativeTo: origin) else { return nil }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
                return nil
            }
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            return nil
        }
    }
}

public struct DiscordPresence: Decodable, Sendable {
    public enum Status: String, Decodable, Sendable {
        case online, idle, dnd, offline
    }

    public let status: Status
    public let activity: String?

    private enum CodingKeys: String, CodingKey {
        case status, activity
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = container.cmsString(forKey: .status).flatMap(Status.init(rawValue:)) ?? .offline
        activity = container.cmsString(forKey: .activity)
    }
}

public struct LetterboxdFilm: Decodable, Sendable {
    public let title: String
    public let year: String?

    public let rating: Double?
    public let liked: Bool
    public let url: String?

    private enum CodingKeys: String, CodingKey {
        case title, year, rating, liked, url
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = container.cmsString(forKey: .title) ?? ""
        year = container.cmsString(forKey: .year)
        rating = container.cmsValue(Double.self, forKey: .rating)
        liked = container.cmsBool(forKey: .liked)
        url = container.cmsString(forKey: .url)
    }

    public var stars: String? {
        guard let rating else { return nil }
        let full = Int(rating.rounded(.down))
        let half = rating.truncatingRemainder(dividingBy: 1) >= 0.5 ? "½" : ""
        return String(repeating: "★", count: full) + half
    }
}

private struct LetterboxdFilmsResponse: Decodable {
    let films: [LetterboxdFilm]
}

public struct PsnTrophy: Decodable, Sendable {
    public let name: String
    public let game: String
    public let type: String?
    public let url: String?

    private enum CodingKeys: String, CodingKey {
        case name, game, type, url
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = container.cmsString(forKey: .name) ?? ""
        game = container.cmsString(forKey: .game) ?? ""
        type = container.cmsString(forKey: .type)
        url = container.cmsString(forKey: .url)
    }

    public var badge: String {
        switch type {
        case "platinum": return "🏆"
        case "gold": return "🥇"
        case "silver": return "🥈"
        case "bronze": return "🥉"
        default: return "🎮"
        }
    }
}

private struct PsnTrophiesResponse: Decodable {
    let trophies: [PsnTrophy]
}

public struct WeatherNow: Decodable, Sendable {
    public let temperature: Double?
    public let emoji: String?
    public let condition: String?

    private enum CodingKeys: String, CodingKey {
        case temperature, emoji, condition
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        temperature = container.cmsValue(Double.self, forKey: .temperature)
        emoji = container.cmsString(forKey: .emoji)
        condition = container.cmsString(forKey: .condition)
    }
}

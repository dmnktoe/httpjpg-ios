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

    public func latestRecord() async -> DiscogsRelease? {
        await get(DiscogsReleasesResponse.self, path: "/api/discogs")?.releases.first
    }

    /// The whole timeline rather than its newest post: the profile that rides
    /// along on the same response carries the avatar and the follower count
    /// the line leads with.
    public func xTimeline() async -> XTimeline? {
        await get(XTimeline.self, path: "/api/x")
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

public struct DiscogsRelease: Decodable, Sendable {
    public let title: String
    public let artist: String
    public let year: String?
    public let format: String?
    public let url: String?
    public let thumb: String?

    private enum CodingKeys: String, CodingKey {
        case title, artist, year, format, url, thumb
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = container.cmsString(forKey: .title) ?? ""
        artist = container.cmsString(forKey: .artist) ?? ""
        year = container.cmsString(forKey: .year)
        format = container.cmsString(forKey: .format)
        url = container.cmsString(forKey: .url)
        thumb = container.cmsString(forKey: .thumb)
    }

    /// How the site writes the record on one line: "Artist — Title".
    public var credit: String {
        artist.isEmpty ? title : "\(artist) — \(title)"
    }
}

private struct DiscogsReleasesResponse: Decodable {
    let releases: [DiscogsRelease]
}

public struct XProfile: Decodable, Sendable {
    public let username: String
    public let avatar: String?
    public let followerCount: Int?

    private enum CodingKeys: String, CodingKey {
        case username, avatar, followerCount
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        username = container.cmsString(forKey: .username) ?? ""
        avatar = container.cmsString(forKey: .avatar)
        followerCount = container.cmsInt(forKey: .followerCount)
    }

    public var handle: String {
        username.isEmpty ? "" : "@\(username)"
    }

    /// Compacted the way the site compacts it — 1.2K, 227M — so a wide count
    /// cannot push the post text off the row. Pinned to en_US because the rest
    /// of the footer is written in English too.
    public var compactFollowerCount: String? {
        guard let followerCount, followerCount >= 0 else { return nil }
        return Double(followerCount).formatted(
            .number.notation(.compactName).precision(.fractionLength(0 ... 1))
                .locale(Locale(identifier: "en_US"))
        )
    }
}

public struct XPost: Decodable, Sendable {
    public let text: String
    public let url: String?
    public let hasMedia: Bool
    public let isQuote: Bool

    private enum CodingKeys: String, CodingKey {
        case text, url, hasMedia, isQuote
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = container.cmsString(forKey: .text) ?? ""
        url = container.cmsString(forKey: .url)
        hasMedia = container.cmsBool(forKey: .hasMedia)
        isQuote = container.cmsBool(forKey: .isQuote)
    }
}

public struct XTimeline: Decodable, Sendable {
    public let profile: XProfile
    public let posts: [XPost]

    private enum CodingKeys: String, CodingKey {
        case profile, posts
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        profile = try container.decode(XProfile.self, forKey: .profile)
        posts = container.cmsArray(XPost.self, forKey: .posts)
    }

    public var latestPost: XPost? { posts.first }
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

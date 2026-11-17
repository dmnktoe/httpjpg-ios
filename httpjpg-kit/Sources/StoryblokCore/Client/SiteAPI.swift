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

    public func xTimeline() async -> XTimeline? {
        await get(XTimeline.self, path: "/api/x")
    }

    public func schalkeStatus() async -> SchalkeStatus? {
        await get(SchalkeStatus.self, path: "/api/schalke")
    }

    public func weather() async -> WeatherNow? {
        await get(WeatherNow.self, path: "/api/weather")
    }

    public func search(query: String, limit: Int = 8) async throws -> SearchResponse {
        let trimmed = String(query.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120))
        guard !trimmed.isEmpty else { return SearchResponse() }

        guard let searchURL = URL(string: "/api/search", relativeTo: origin)?.absoluteURL,
              var components = URLComponents(url: searchURL, resolvingAgainstBaseURL: false)
        else { throw SiteAPIError.badURL }
        components.queryItems = [
            URLQueryItem(name: "q", value: trimmed),
            URLQueryItem(name: "limit", value: String(min(max(limit, 1), 20))),
        ]
        guard let url = components.url else { throw SiteAPIError.badURL }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SiteAPIError.transport("missing response")
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw SiteAPIError.http(status: http.statusCode)
        }
        return try JSONDecoder().decode(SearchResponse.self, from: data)
    }

    public func ask(question: String) -> AsyncThrowingStream<AskStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await self.writeAskStream(question: question, into: continuation)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func writeAskStream(
        question: String,
        into continuation: AsyncThrowingStream<AskStreamEvent, Error>.Continuation
    ) async throws {
        let trimmed = String(question.trimmingCharacters(in: .whitespacesAndNewlines).prefix(500))
        guard !trimmed.isEmpty else { throw SiteAPIError.http(status: 400) }
        guard let url = URL(string: "/api/ask", relativeTo: origin)?.absoluteURL else {
            throw SiteAPIError.badURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        request.httpBody = try JSONSerialization.data(withJSONObject: ["question": trimmed])

        let (bytes, response) = try await session.bytes(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SiteAPIError.transport("missing response")
        }
        if http.statusCode == 503 {
            throw SiteAPIError.askUnavailable
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw SiteAPIError.http(status: http.statusCode)
        }

        for try await line in bytes.lines {
            try Task.checkCancellation()
            if let event = AskStreamEvent.parse(line) {
                continuation.yield(event)
            }
        }
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
    public let activityIcon: String?

    private enum CodingKeys: String, CodingKey {
        case status, activity, activityDetails
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = container.cmsString(forKey: .status).flatMap(Status.init(rawValue:)) ?? .offline
        activity = container.cmsString(forKey: .activity)
        activityIcon = container.cmsValue(ActivityDetails.self, forKey: .activityDetails)?.icon
    }

    private struct ActivityDetails: Decodable {
        let icon: String?

        private enum CodingKeys: String, CodingKey {
            case icon
        }

        init(from decoder: any Decoder) throws {
            icon = try decoder.container(keyedBy: CodingKeys.self).cmsString(forKey: .icon)
        }
    }
}

public struct LetterboxdFilm: Decodable, Sendable {
    public let title: String
    public let year: String?

    public let rating: Double?
    public let liked: Bool
    public let url: String?
    public let poster: String?
    public let watchedDate: Date?

    private enum CodingKeys: String, CodingKey {
        case title, year, rating, liked, url, poster, watchedDate
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = container.cmsString(forKey: .title) ?? ""
        year = container.cmsString(forKey: .year)
        rating = container.cmsValue(Double.self, forKey: .rating)
        liked = container.cmsBool(forKey: .liked)
        url = container.cmsString(forKey: .url)
        poster = container.cmsString(forKey: .poster)
        watchedDate = StoryblokDate.parse(container.cmsString(forKey: .watchedDate))
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
    public let image: String?
    public let earnedAt: Date?

    private enum CodingKeys: String, CodingKey {
        case name, game, type, url, image, earnedAt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = container.cmsString(forKey: .name) ?? ""
        game = container.cmsString(forKey: .game) ?? ""
        type = container.cmsString(forKey: .type)
        url = container.cmsString(forKey: .url)
        image = container.cmsString(forKey: .image)
        earnedAt = StoryblokDate.parse(container.cmsString(forKey: .earnedAt))
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
    public let addedAt: Date?

    private enum CodingKeys: String, CodingKey {
        case title, artist, year, format, url, thumb, addedAt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = container.cmsString(forKey: .title) ?? ""
        artist = container.cmsString(forKey: .artist) ?? ""
        year = container.cmsString(forKey: .year)
        format = container.cmsString(forKey: .format)
        url = container.cmsString(forKey: .url)
        thumb = container.cmsString(forKey: .thumb)
        addedAt = StoryblokDate.parse(container.cmsString(forKey: .addedAt))
    }

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

public struct SchalkeFixture: Decodable, Sendable {
    public enum Outcome: String, Sendable {
        case win, draw, loss
    }

    public let home: String
    public let away: String
    public let homeGoals: Int
    public let awayGoals: Int
    public let homeCrest: Data?
    public let awayCrest: Data?
    public let outcome: Outcome
    public let playedAt: Date?

    private enum CodingKeys: String, CodingKey {
        case home, away, homeGoals, awayGoals, homeCrest, awayCrest, outcome, playedAt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        home = container.cmsString(forKey: .home) ?? ""
        away = container.cmsString(forKey: .away) ?? ""
        homeGoals = container.cmsInt(forKey: .homeGoals) ?? 0
        awayGoals = container.cmsInt(forKey: .awayGoals) ?? 0
        homeCrest = container.cmsString(forKey: .homeCrest).flatMap(Self.imageData(fromDataURI:))
        awayCrest = container.cmsString(forKey: .awayCrest).flatMap(Self.imageData(fromDataURI:))
        outcome = container.cmsString(forKey: .outcome).flatMap(Outcome.init(rawValue:)) ?? .draw
        playedAt = StoryblokDate.parse(container.cmsString(forKey: .playedAt))
    }

    public var score: String {
        "\(home) \(homeGoals):\(awayGoals) \(away)"
    }

    static func imageData(fromDataURI uri: String) -> Data? {
        guard uri.hasPrefix("data:image/"), let marker = uri.range(of: ";base64,") else { return nil }
        return Data(base64Encoded: String(uri[marker.upperBound...]))
    }
}

public struct SchalkeUpcoming: Decodable, Sendable {
    public let home: String
    public let away: String
    public let homeCrest: Data?
    public let awayCrest: Data?
    public let kickoff: Date?

    private enum CodingKeys: String, CodingKey {
        case home, away, homeCrest, awayCrest, kickoff
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        home = container.cmsString(forKey: .home) ?? ""
        away = container.cmsString(forKey: .away) ?? ""
        homeCrest = container.cmsString(forKey: .homeCrest).flatMap(SchalkeFixture.imageData(fromDataURI:))
        awayCrest = container.cmsString(forKey: .awayCrest).flatMap(SchalkeFixture.imageData(fromDataURI:))
        kickoff = StoryblokDate.parse(container.cmsString(forKey: .kickoff))
    }

    public var pairing: String {
        "\(home) – \(away)"
    }

    public func kickoffLabel(now: Date = .now) -> String? {
        guard let kickoff else { return nil }
        if kickoff <= now { return "live" }
        let day = kickoff.timeIntervalSince(now) < Self.weekdayWindow
            ? Self.weekday.string(from: kickoff)
            : Self.date.string(from: kickoff)
        return "\(day) \(Self.time.string(from: kickoff))"
    }

    private static let weekdayWindow: TimeInterval = 6 * 24 * 60 * 60

    private static let time = berlin("HH:mm")
    private static let weekday = berlin("EEE")
    private static let date = berlin("d MMM")

    private static func berlin(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.timeZone = TimeZone(identifier: "Europe/Berlin") ?? .gmt
        formatter.dateFormat = format
        return formatter
    }
}

public struct SchalkeStanding: Decodable, Sendable {
    public enum Trend: String, Sendable {
        case up, down, same
    }

    public let position: Int
    public let previousPosition: Int?
    public let trend: Trend
    public let points: Int?

    private enum CodingKeys: String, CodingKey {
        case position, previousPosition, trend, points
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        position = container.cmsInt(forKey: .position) ?? 0
        previousPosition = container.cmsInt(forKey: .previousPosition)
        trend = container.cmsString(forKey: .trend).flatMap(Trend.init(rawValue:)) ?? .same
        points = container.cmsInt(forKey: .points)
    }
}

public struct SchalkeStatus: Decodable, Sendable {
    public let fixture: SchalkeFixture?
    public let upcoming: SchalkeUpcoming?
    public let standing: SchalkeStanding?
    public let url: String?

    private enum CodingKeys: String, CodingKey {
        case fixture, upcoming, standing, url
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fixture = container.cmsValue(SchalkeFixture.self, forKey: .fixture)
        let upcoming = container.cmsValue(SchalkeUpcoming.self, forKey: .upcoming)
        let standing = container.cmsValue(SchalkeStanding.self, forKey: .standing)
        self.fixture = fixture.flatMap { $0.home.isEmpty || $0.away.isEmpty ? nil : $0 }
        self.upcoming = upcoming.flatMap { $0.home.isEmpty || $0.away.isEmpty ? nil : $0 }
        self.standing = standing.flatMap { $0.position > 0 ? $0 : nil }
        url = container.cmsString(forKey: .url)
    }

    public var isEmpty: Bool {
        fixture == nil && upcoming == nil && standing == nil
    }
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

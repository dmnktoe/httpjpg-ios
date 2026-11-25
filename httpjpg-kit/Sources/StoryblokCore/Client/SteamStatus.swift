import Foundation

public struct SteamStatus: Decodable, Sendable {
    public struct Game: Decodable, Sendable {
        public let appId: Int
        public let name: String
        public let minutesTwoWeeks: Int
        public let minutesTotal: Int
        public let lastPlayedAt: Date?
        public let icon: Data?
        public let url: String?

        private enum CodingKeys: String, CodingKey {
            case appId, name, minutesTwoWeeks, minutesTotal, lastPlayedAt, icon, url
        }

        init(appId: Int, name: String) {
            self.appId = appId
            self.name = name
            minutesTwoWeeks = 0
            minutesTotal = 0
            lastPlayedAt = nil
            icon = nil
            url = "https://store.steampowered.com/app/\(appId)/"
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            appId = container.cmsInt(forKey: .appId) ?? 0
            name = container.cmsString(forKey: .name) ?? ""
            minutesTwoWeeks = container.cmsInt(forKey: .minutesTwoWeeks) ?? 0
            minutesTotal = container.cmsInt(forKey: .minutesTotal) ?? 0
            lastPlayedAt = StoryblokDate.parse(container.cmsString(forKey: .lastPlayedAt))
            icon = PixelImage.data(fromDataURI: container.cmsString(forKey: .icon))
            url = container.cmsString(forKey: .url)
        }

        public var recentPlaytime: String? {
            guard minutesTwoWeeks > 0 else { return nil }
            return "\(SteamStatus.playtime(minutesTwoWeeks)) / 2w"
        }

        public var lifetimePlaytime: String? {
            guard minutesTotal > 0 else { return nil }
            return "\(SteamStatus.playtime(minutesTotal)) total"
        }
    }

    public struct InGame: Decodable, Sendable {
        public let appId: Int
        public let name: String

        private enum CodingKeys: String, CodingKey {
            case appId, name
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            appId = container.cmsInt(forKey: .appId) ?? 0
            name = container.cmsString(forKey: .name) ?? ""
        }
    }

    public enum Kind: String, Sendable {
        case playing, recent, lifetime, profile
    }

    public struct Line: Sendable {
        public let kind: Kind
        public let game: Game?
        public let detail: String?
    }

    public let name: String
    public let avatar: Data?
    public let url: String?
    public let isOnline: Bool
    public let inGame: InGame?
    public let games: [Game]

    private enum CodingKeys: String, CodingKey {
        case profile, games
    }

    private enum ProfileKeys: String, CodingKey {
        case name, avatar, url, isOnline, inGame
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let profile = try? container.nestedContainer(keyedBy: ProfileKeys.self, forKey: .profile)
        name = profile?.cmsString(forKey: .name) ?? ""
        avatar = PixelImage.data(fromDataURI: profile?.cmsString(forKey: .avatar))
        url = profile?.cmsString(forKey: .url)
        isOnline = profile?.cmsBool(forKey: .isOnline) ?? false
        inGame = profile?.cmsValue(InGame.self, forKey: .inGame).flatMap { $0.appId > 0 && !$0.name.isEmpty ? $0 : nil }
        games = container.cmsArray(Game.self, forKey: .games).filter { $0.appId > 0 && !$0.name.isEmpty }
    }

    public var featured: Game? {
        guard let inGame else { return games.first }
        return games.first { $0.appId == inGame.appId } ?? Game(appId: inGame.appId, name: inGame.name)
    }

    public var isPlaying: Bool {
        guard let inGame, let featured else { return false }
        return featured.appId == inGame.appId
    }

    public var line: Line? {
        guard let game = featured else {
            return name.isEmpty ? nil : Line(kind: .profile, game: nil, detail: isOnline ? "online" : nil)
        }
        if isPlaying {
            return Line(kind: .playing, game: game, detail: game.recentPlaytime)
        }
        if let recent = game.recentPlaytime {
            return Line(kind: .recent, game: game, detail: recent)
        }
        return Line(kind: .lifetime, game: game, detail: game.lifetimePlaytime)
    }

    static func playtime(_ minutes: Int) -> String {
        minutes < 60 ? "\(minutes)m" : "\(Int((Double(minutes) / 60).rounded()))h"
    }
}

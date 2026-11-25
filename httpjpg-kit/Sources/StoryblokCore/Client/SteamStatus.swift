import Foundation

public struct SteamStatus: Decodable, Sendable {
    public struct Game: Decodable, Sendable {
        public let appId: Int
        public let name: String
        /// Minutes played in the last two weeks.
        public let minutesTwoWeeks: Int
        public let icon: Data?
        public let url: String?

        private enum CodingKeys: String, CodingKey {
            case appId, name, minutesTwoWeeks, icon, url
        }

        init(appId: Int, name: String) {
            self.appId = appId
            self.name = name
            minutesTwoWeeks = 0
            icon = nil
            url = "https://store.steampowered.com/app/\(appId)/"
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            appId = container.cmsInt(forKey: .appId) ?? 0
            name = container.cmsString(forKey: .name) ?? ""
            minutesTwoWeeks = container.cmsInt(forKey: .minutesTwoWeeks) ?? 0
            icon = PixelImage.data(fromDataURI: container.cmsString(forKey: .icon))
            url = container.cmsString(forKey: .url)
        }

        /// `14h / 2w`, or `45m / 2w` for a short fortnight; nil when nothing was played.
        public var recentPlaytime: String? {
            guard minutesTwoWeeks > 0 else { return nil }
            let amount = minutesTwoWeeks < 60
                ? "\(minutesTwoWeeks)m"
                : "\(Int((Double(minutesTwoWeeks) / 60).rounded()))h"
            return "\(amount) / 2w"
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

    public let inGame: InGame?
    public let games: [Game]

    private enum CodingKeys: String, CodingKey {
        case profile, games
    }

    private enum ProfileKeys: String, CodingKey {
        case inGame
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let profile = try? container.nestedContainer(keyedBy: ProfileKeys.self, forKey: .profile)
        inGame = profile?.cmsValue(InGame.self, forKey: .inGame).flatMap { $0.appId > 0 && !$0.name.isEmpty ? $0 : nil }
        games = container.cmsArray(Game.self, forKey: .games).filter { $0.appId > 0 && !$0.name.isEmpty }
    }

    /// Mirrors the web's `featuredSteamGame`: the game running now, else the most played lately.
    public var featured: Game? {
        guard let inGame else { return games.first }
        return games.first { $0.appId == inGame.appId } ?? Game(appId: inGame.appId, name: inGame.name)
    }

    public var isPlaying: Bool {
        guard let inGame, let featured else { return false }
        return featured.appId == inGame.appId
    }
}

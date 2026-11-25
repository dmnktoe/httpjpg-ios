import Foundation

public struct LastfmScrobbles: Decodable, Sendable {
    public struct Track: Decodable, Sendable {
        public let title: String
        public let artist: String
        public let url: String?
        public let image: Data?
        public let isNowPlaying: Bool
        public let isLoved: Bool
        public let scrobbledAt: Date?

        private enum CodingKeys: String, CodingKey {
            case title, artist, url, image, nowPlaying, loved, scrobbledAt
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            title = container.cmsString(forKey: .title) ?? ""
            artist = container.cmsString(forKey: .artist) ?? ""
            url = container.cmsString(forKey: .url)
            image = PixelImage.data(fromDataURI: container.cmsString(forKey: .image))
            isNowPlaying = container.cmsBool(forKey: .nowPlaying)
            isLoved = container.cmsBool(forKey: .loved)
            scrobbledAt = StoryblokDate.parse(container.cmsString(forKey: .scrobbledAt))
        }
    }

    public let tracks: [Track]
    public let total: Int?

    private enum CodingKeys: String, CodingKey {
        case tracks, total
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tracks = container.cmsArray(Track.self, forKey: .tracks).filter { !$0.title.isEmpty && !$0.artist.isEmpty }
        total = container.cmsInt(forKey: .total)
    }

    public var latest: Track? { tracks.first }

    public var compactTotal: String? {
        guard let total, total >= 0 else { return nil }
        return CompactCount.format(total)
    }
}

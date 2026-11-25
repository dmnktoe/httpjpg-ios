import Foundation

public struct YoutubeStatus: Decodable, Sendable {
    public struct Channel: Decodable, Sendable {
        public let title: String
        public let avatar: Data?
        public let url: String?
        /// Nil when the channel hides it; YouTube rounds it to three significant figures.
        public let subscriberCount: Int?

        private enum CodingKeys: String, CodingKey {
            case title, avatar, url, subscriberCount
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            title = container.cmsString(forKey: .title) ?? ""
            avatar = PixelImage.data(fromDataURI: container.cmsString(forKey: .avatar))
            url = container.cmsString(forKey: .url)
            subscriberCount = container.cmsInt(forKey: .subscriberCount)
        }

        public var compactSubscriberCount: String? {
            guard let subscriberCount, subscriberCount >= 0 else { return nil }
            return CompactCount.format(subscriberCount)
        }
    }

    public struct Video: Decodable, Sendable {
        public let title: String
        public let url: String?
        public let thumbnail: Data?
        public let publishedAt: Date?

        private enum CodingKeys: String, CodingKey {
            case title, url, thumbnail, publishedAt
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            title = container.cmsString(forKey: .title) ?? ""
            url = container.cmsString(forKey: .url)
            thumbnail = PixelImage.data(fromDataURI: container.cmsString(forKey: .thumbnail))
            publishedAt = StoryblokDate.parse(container.cmsString(forKey: .publishedAt))
        }
    }

    public let channel: Channel
    public let videos: [Video]

    private enum CodingKeys: String, CodingKey {
        case channel, videos
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        channel = try container.decode(Channel.self, forKey: .channel)
        videos = container.cmsArray(Video.self, forKey: .videos).filter { !$0.title.isEmpty }
    }

    public var latestVideo: Video? { videos.first }
}

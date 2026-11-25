import Foundation

/// The body of `POST /api/feed/posts`: uploads are named by the asset id the
/// site handed out when it signed them.
public struct FeedPublishRequest: Encodable, Equatable, Sendable {
    public struct Image: Encodable, Equatable, Sendable {
        public var assetId: Int
        public var fit: PostImageBlok.Fit
        public var alt: String?

        public init(assetId: Int, fit: PostImageBlok.Fit, alt: String? = nil) {
            self.assetId = assetId
            self.fit = fit
            self.alt = alt
        }

        private enum CodingKeys: String, CodingKey {
            case assetId, fit, alt
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(assetId, forKey: .assetId)
            try container.encode(fit.rawValue, forKey: .fit)
            try container.encodeIfPresent(alt, forKey: .alt)
        }
    }

    public struct Music: Encodable, Equatable, Sendable {
        public enum Source: String, Encodable, Sendable, CaseIterable {
            case mp3, spotify, soundcloud
        }

        public var source: Source
        /// Share or file URL. An uploaded file sends `assetId` instead.
        public var src: String?
        public var assetId: Int?
        public var title: String?
        public var artist: String?
        public var artworkAssetId: Int?

        public init(
            source: Source,
            src: String? = nil,
            assetId: Int? = nil,
            title: String? = nil,
            artist: String? = nil,
            artworkAssetId: Int? = nil
        ) {
            self.source = source
            self.src = src
            self.assetId = assetId
            self.title = title
            self.artist = artist
            self.artworkAssetId = artworkAssetId
        }
    }

    public var caption: String
    public var format: PostBlok.Format
    public var images: [Image]
    public var music: Music?

    public init(
        caption: String,
        format: PostBlok.Format,
        images: [Image],
        music: Music? = nil
    ) {
        self.caption = caption
        self.format = format
        self.images = images
        self.music = music
    }

    private enum CodingKeys: String, CodingKey {
        case caption, format, images, music
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(caption, forKey: .caption)
        try container.encode(format.rawValue, forKey: .format)
        try container.encode(images, forKey: .images)
        try container.encodeIfPresent(music, forKey: .music)
    }
}

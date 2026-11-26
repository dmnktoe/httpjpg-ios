import Foundation

public struct FeedEditRequest: Encodable, Equatable, Sendable {
    public struct Image: Encodable, Equatable, Sendable {
        public var uid: String
        public var fit: PostImageBlok.Fit
        public var alt: String?

        public init(uid: String, fit: PostImageBlok.Fit, alt: String? = nil) {
            self.uid = uid
            self.fit = fit
            self.alt = alt
        }

        private enum CodingKeys: String, CodingKey {
            case uid, fit, alt
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(uid, forKey: .uid)
            try container.encode(fit.rawValue, forKey: .fit)
            try container.encodeIfPresent(alt, forKey: .alt)
        }
    }

    public var caption: String
    public var format: PostBlok.Format
    public var images: [Image]

    public init(caption: String, format: PostBlok.Format, images: [Image]) {
        self.caption = caption
        self.format = format
        self.images = images
    }

    public init(post: PostBlok, caption: String) {
        self.init(
            caption: caption,
            format: post.format,
            images: post.images.map { Image(uid: $0.id, fit: $0.fit, alt: $0.alt) }
        )
    }

    private enum CodingKeys: String, CodingKey {
        case caption, format, images
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(caption, forKey: .caption)
        try container.encode(format.rawValue, forKey: .format)
        try container.encode(images, forKey: .images)
    }
}

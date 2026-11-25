import Foundation

/// One image of a feed post. Nested under `post.images`, never a body blok.
public struct PostImageBlok: Decodable, Identifiable {
    public enum Fit: String, Sendable {
        /// Fills the post's frame; the file was cropped on the device before upload.
        case cover
        /// Shows the whole file, letterboxed in the page colour.
        case contain
    }

    public let id: String
    public let image: StoryblokAsset?
    public let alt: String?
    public let fit: Fit

    private enum CodingKeys: String, CodingKey {
        case image, alt, fit
    }

    public init(from decoder: any Decoder) throws {
        let envelope = try BlokEnvelope(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = envelope.uid
        image = container.cmsValue(StoryblokAsset.self, forKey: .image)
        alt = container.cmsString(forKey: .alt)
        fit = container.cmsString(forKey: .fit).flatMap(Fit.init(rawValue:)) ?? .cover
    }

    public var filename: String? {
        guard let image, !image.isEmpty, !image.isVideo else { return nil }
        return image.filename
    }

    public var accessibilityText: String? {
        alt ?? image?.alt.flatMap { $0.isEmpty ? nil : $0 }
    }
}

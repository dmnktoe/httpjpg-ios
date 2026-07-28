import Foundation

/// A Storyblok asset field — the Swift counterpart of `StoryblokImage` /
/// `StoryblokVideoAsset` in `storyblok-utils/src/types.ts`.
///
/// `filename` is modelled as optional even though the web type declares it
/// required: an emptied asset field still serialises as an object with every
/// value set to `null`, which would otherwise fail to decode.
public struct StoryblokAsset: Decodable, Hashable, Sendable, Identifiable {
    public let id: Int?
    public let alt: String?
    public let name: String?
    public let title: String?
    public let focus: String?
    public let filename: String?
    public let copyright: String?
    public let contentType: String?
    public let isExternalURL: Bool

    private enum CodingKeys: String, CodingKey {
        case id
        case alt
        case name
        case title
        case focus
        case filename
        case copyright
        case contentType = "content_type"
        case isExternalURL = "is_external_url"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        alt = try container.decodeIfPresent(String.self, forKey: .alt)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        focus = try container.decodeIfPresent(String.self, forKey: .focus)
        filename = try container.decodeIfPresent(String.self, forKey: .filename)
        copyright = try container.decodeIfPresent(String.self, forKey: .copyright)
        contentType = try container.decodeIfPresent(String.self, forKey: .contentType)
        isExternalURL = try container.decodeIfPresent(Bool.self, forKey: .isExternalURL) ?? false
    }

    /// `true` when the asset is empty — Storyblok keeps the object around.
    public var isEmpty: Bool { filename?.isEmpty ?? true }

    public var isVideo: Bool {
        ImageService.isVideo(filename: filename, contentType: contentType)
    }

    /// Best available alternative text, falling back through the CMS fields.
    public func accessibilityText(fallback: String) -> String {
        for candidate in [alt, title, name] {
            if let candidate, !candidate.isEmpty { return candidate }
        }
        return fallback
    }
}

public extension Array where Element == StoryblokAsset {
    /// First non-video asset filename — the web's `firstImageFilename`.
    var firstImageFilename: String? {
        first { !$0.isEmpty && !$0.isVideo }?.filename
    }

    var images: [StoryblokAsset] {
        filter { !$0.isEmpty && !$0.isVideo }
    }
}

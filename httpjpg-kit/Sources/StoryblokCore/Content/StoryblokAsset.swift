import Foundation

public struct StoryblokAsset: Decodable, Hashable, Sendable, Identifiable {
    public let id: Int?
    public let alt: String?
    public let name: String?
    public let title: String?
    public let focus: String?
    public let filename: String?
    public let copyright: String?
    public let source: String?
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
        case source
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
        source = try container.decodeIfPresent(String.self, forKey: .source)
        contentType = try container.decodeIfPresent(String.self, forKey: .contentType)
        isExternalURL = try container.decodeIfPresent(Bool.self, forKey: .isExternalURL) ?? false
    }

    public var copyrightText: String? {
        copyright.flatMap { $0.isEmpty ? nil : $0 }
    }

    public var sourceText: String? {
        source.flatMap { $0.isEmpty ? nil : $0 }
    }

    public var hasCredit: Bool { copyrightText != nil || sourceText != nil }

    public var isEmpty: Bool { filename?.isEmpty ?? true }

    public var isVideo: Bool {
        ImageService.isVideo(filename: filename, contentType: contentType)
    }

    public var isGIF: Bool {
        ImageService.isGIF(filename: filename, contentType: contentType)
    }

    public func accessibilityText(fallback: String) -> String {
        for candidate in [alt, title, name] {
            if let candidate, !candidate.isEmpty { return candidate }
        }
        return fallback
    }
}

public extension Array where Element == StoryblokAsset {
    var firstImageFilename: String? {
        first { !$0.isEmpty && !$0.isVideo }?.filename
    }

    var images: [StoryblokAsset] {
        filter { !$0.isEmpty && !$0.isVideo }
    }
}

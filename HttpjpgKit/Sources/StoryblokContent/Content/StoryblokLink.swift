import Foundation

/// A Storyblok multilink field — the Swift counterpart of `StoryblokLink`.
public struct StoryblokLink: Decodable, Hashable, Sendable {
    public enum Kind: String, Decodable, Sendable {
        case url
        case story
        case asset
        case email
    }

    public let id: String?
    public let url: String?
    public let cachedURL: String?
    public let anchor: String?
    public let email: String?
    public let target: String?
    public let linkType: Kind

    private enum CodingKeys: String, CodingKey {
        case id
        case url
        case cachedURL = "cached_url"
        case anchor
        case email
        case target
        case linkType = "linktype"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        cachedURL = try container.decodeIfPresent(String.self, forKey: .cachedURL)
        anchor = try container.decodeIfPresent(String.self, forKey: .anchor)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        target = try container.decodeIfPresent(String.self, forKey: .target)
        let rawLinkType = try container.decodeIfPresent(String.self, forKey: .linkType)
        linkType = rawLinkType.flatMap(Kind.init(rawValue:)) ?? .url
    }

    /// The href the web's `storyblokHref` would produce.
    public var href: String? {
        switch linkType {
        case .email:
            return email.flatMap { $0.isEmpty ? nil : "mailto:\($0)" }
        case .url, .asset:
            return nonEmpty(url) ?? nonEmpty(cachedURL)
        case .story:
            guard let slug = nonEmpty(cachedURL) ?? nonEmpty(url) else { return nil }
            let path = slug.hasPrefix("/") ? slug : "/\(slug)"
            return anchor.map { $0.isEmpty ? path : "\(path)#\($0)" } ?? path
        }
    }

    /// An absolute `URL`, resolved against the site origin for internal links.
    public func resolvedURL(siteOrigin: URL) -> URL? {
        guard let href else { return nil }
        if href.hasPrefix("http://") || href.hasPrefix("https://") || href.hasPrefix("mailto:") {
            return URL(string: href)
        }
        return URL(string: href, relativeTo: siteOrigin)?.absoluteURL
    }

    public var isEmpty: Bool { href == nil }

    private func nonEmpty(_ value: String?) -> String? {
        guard let value, !value.isEmpty else { return nil }
        return value
    }
}

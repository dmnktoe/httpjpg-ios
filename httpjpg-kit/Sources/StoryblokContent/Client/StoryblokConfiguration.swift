import Foundation

public enum ContentVersion: String, Sendable {
    case draft
    case published
}

public enum ContentRegion: String, Sendable, CaseIterable {
    case eu
    case usa
    case can
    case aus
    case chn

    var baseURL: URL {
        switch self {
        case .eu: return URL(string: "https://api.storyblok.com/v2/cdn/")!
        case .usa: return URL(string: "https://api-us.storyblok.com/v2/cdn/")!
        case .can: return URL(string: "https://api-ca.storyblok.com/v2/cdn/")!
        case .aus: return URL(string: "https://api-ap.storyblok.com/v2/cdn/")!
        case .chn: return URL(string: "https://app.storyblokchina.cn/v2/cdn/")!
        }
    }
}

public struct StoryblokConfiguration: Sendable {
    public var accessToken: String
    public var version: ContentVersion
    public var region: ContentRegion

    public var siteOrigin: URL

    public var source: ContentSource

    public init(
        accessToken: String,
        version: ContentVersion = .published,
        region: ContentRegion = .eu,
        siteOrigin: URL = URL(string: "https://www.httpjpg.com")!,
        source: ContentSource = .network
    ) {
        self.accessToken = accessToken
        self.version = version
        self.region = region
        self.siteOrigin = siteOrigin
        self.source = source
    }

    public enum InfoPlistKey {
        public static let accessToken = "STORYBLOK_ACCESS_TOKEN"
        public static let version = "STORYBLOK_VERSION"
        public static let region = "STORYBLOK_REGION"
        public static let siteOrigin = "SITE_ORIGIN"
        public static let source = "CONTENT_SOURCE"
    }

    public static let mockAccessToken = "mock"

    public static func fromBundle(_ bundle: Bundle = .main) throws -> StoryblokConfiguration {
        func string(_ key: String) -> String? {
            guard let value = bundle.object(forInfoDictionaryKey: key) as? String else { return nil }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        let source = ContentSource.named(string(InfoPlistKey.source))
        if source == .mock {
            MockContentProtocol.install()
        }

        guard let token = string(InfoPlistKey.accessToken), token != "REPLACE_ME" else {
            guard source == .mock else { throw ContentError.missingAccessToken }
            return StoryblokConfiguration(accessToken: mockAccessToken, source: .mock)
        }

        let origin = string(InfoPlistKey.siteOrigin)
            .flatMap(URL.init(string:)) ?? URL(string: "https://www.httpjpg.com")!

        return StoryblokConfiguration(
            accessToken: token,
            version: string(InfoPlistKey.version).flatMap(ContentVersion.init(rawValue:)) ?? .published,
            region: string(InfoPlistKey.region).flatMap(ContentRegion.init(rawValue:)) ?? .eu,
            siteOrigin: origin,
            source: source
        )
    }
}

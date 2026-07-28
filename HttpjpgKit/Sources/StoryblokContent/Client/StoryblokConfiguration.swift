import Foundation

/// Which version of the content to read.
public enum ContentVersion: String, Sendable {
    case draft
    case published
}

/// The space's server location.
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

/// Everything ``ContentClient`` needs to talk to a Storyblok space.
///
/// The access token is read from the app bundle rather than compiled in, so
/// `Config/Secrets.xcconfig` stays out of version control the same way
/// `STORYBLOK_*` stays in `.env` on the web.
public struct StoryblokConfiguration: Sendable {
    public var accessToken: String
    public var version: ContentVersion
    public var region: ContentRegion
    /// Origin used to resolve internal Storyblok links to real URLs.
    public var siteOrigin: URL

    public init(
        accessToken: String,
        version: ContentVersion = .published,
        region: ContentRegion = .eu,
        siteOrigin: URL = URL(string: "https://www.httpjpg.com")!
    ) {
        self.accessToken = accessToken
        self.version = version
        self.region = region
        self.siteOrigin = siteOrigin
    }

    public enum InfoPlistKey {
        public static let accessToken = "STORYBLOK_ACCESS_TOKEN"
        public static let version = "STORYBLOK_VERSION"
        public static let region = "STORYBLOK_REGION"
        public static let siteOrigin = "SITE_ORIGIN"
    }

    /// Builds a configuration from the app's `Info.plist`.
    ///
    /// - Throws: ``ContentError/missingAccessToken`` when the token key is
    ///   absent or still holds the placeholder from `Secrets.example.xcconfig`.
    public static func fromBundle(_ bundle: Bundle = .main) throws -> StoryblokConfiguration {
        func string(_ key: String) -> String? {
            guard let value = bundle.object(forInfoDictionaryKey: key) as? String else { return nil }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        guard let token = string(InfoPlistKey.accessToken), token != "REPLACE_ME" else {
            throw ContentError.missingAccessToken
        }

        let origin = string(InfoPlistKey.siteOrigin)
            .flatMap(URL.init(string:)) ?? URL(string: "https://www.httpjpg.com")!

        return StoryblokConfiguration(
            accessToken: token,
            version: string(InfoPlistKey.version).flatMap(ContentVersion.init(rawValue:)) ?? .published,
            region: string(InfoPlistKey.region).flatMap(ContentRegion.init(rawValue:)) ?? .eu,
            siteOrigin: origin
        )
    }
}

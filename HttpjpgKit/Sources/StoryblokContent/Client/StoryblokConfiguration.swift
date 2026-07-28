import Foundation
import URLSessionExtension

/// Everything ``ContentClient`` needs to talk to a Storyblok space.
///
/// The access token is read from the app bundle rather than compiled in, so
/// `Config/Secrets.xcconfig` stays out of version control the same way
/// `STORYBLOK_*` stays in `.env` on the web.
public struct StoryblokConfiguration: Sendable {
    public var accessToken: String
    public var version: Api.Version
    public var region: Api.Region
    /// Origin used to resolve internal Storyblok links to real URLs.
    public var siteOrigin: URL

    public init(
        accessToken: String,
        version: Api.Version = .published,
        region: Api.Region = .eu,
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

        let version: Api.Version = string(InfoPlistKey.version) == "draft" ? .draft : .published
        let origin = string(InfoPlistKey.siteOrigin)
            .flatMap(URL.init(string:)) ?? URL(string: "https://www.httpjpg.com")!

        return StoryblokConfiguration(
            accessToken: token,
            version: version,
            region: region(from: string(InfoPlistKey.region)),
            siteOrigin: origin
        )
    }

    static func region(from raw: String?) -> Api.Region {
        switch raw?.lowercased() {
        case "usa", "us": return .usa
        case "can", "ca": return .can
        case "aus", "ap": return .aus
        case "chn", "cn": return .chn
        default: return .eu
        }
    }
}

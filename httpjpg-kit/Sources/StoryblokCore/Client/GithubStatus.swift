import Foundation

public struct GithubStatus: Decodable, Sendable {
    public struct Activity: Decodable, Sendable {
        public let kind: String
        public let verb: String
        public let repo: String
        public let detail: String?
        public let url: String?
        public let createdAt: Date?

        private enum CodingKeys: String, CodingKey {
            case kind, verb, repo, detail, url, createdAt
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            kind = container.cmsString(forKey: .kind) ?? ""
            verb = container.cmsString(forKey: .verb) ?? ""
            repo = container.cmsString(forKey: .repo) ?? ""
            detail = container.cmsString(forKey: .detail)
            url = container.cmsString(forKey: .url)
            createdAt = StoryblokDate.parse(container.cmsString(forKey: .createdAt))
        }
    }

    public let avatar: Data?
    public let activity: [Activity]

    private enum CodingKeys: String, CodingKey {
        case profile, activity
    }

    private enum ProfileKeys: String, CodingKey {
        case avatar
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let profile = try? container.nestedContainer(keyedBy: ProfileKeys.self, forKey: .profile)
        avatar = PixelImage.data(fromDataURI: profile?.cmsString(forKey: .avatar))
        activity = container.cmsArray(Activity.self, forKey: .activity)
            .filter { !$0.verb.isEmpty && !$0.repo.isEmpty }
    }

    public var latest: Activity? { activity.first }
}

import Foundation
import StoryblokClient

public struct PageSummary: Identifiable, Hashable, Sendable {
    public let id: String
    public let slug: String
    public let fullSlug: String
    public let title: String

    public let component: String
    public let isDark: Bool
    public let updatedAt: Date?

    public init(story: Story<StoryOverview>) {
        id = story.uuid.uuidString
        slug = story.fullSlug
        fullSlug = story.fullSlug
        title = story.content.title ?? story.name
        component = story.content.component
        isDark = story.content.isDark
        updatedAt = story.publishedAt ?? story.updatedAt
    }
}

public struct StoryOverview: Decodable, Sendable {
    public let component: String
    public let title: String?
    public let isDark: Bool

    private enum CodingKeys: String, CodingKey {
        case component, title, isDark
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        component = container.cmsString(forKey: .component) ?? ""
        title = container.cmsString(forKey: .title)
        isDark = container.cmsBool(forKey: .isDark)
    }
}

public extension StorySlug {
    static func isHiddenFromPageIndex(_ slug: String, component: String) -> Bool {
        slug == config || slug == home || component == "config" || component == "work"
    }
}

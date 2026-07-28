import Foundation
import StoryblokClient

/// A row in the page index — enough to list a story without decoding its body.
public struct PageSummary: Identifiable, Hashable, Sendable {
    public let id: String
    public let slug: String
    public let fullSlug: String
    public let title: String
    /// The story's content type, so the list can say what it is opening.
    public let component: String
    public let updatedAt: Date?

    public init(story: Story<StoryOverview>) {
        id = story.uuid.uuidString
        slug = story.fullSlug
        fullSlug = story.fullSlug
        title = story.content.title ?? story.name
        component = story.content.component
        updatedAt = story.publishedAt ?? story.updatedAt
    }
}

/// The cheapest useful decoding of a story's content: what it is, and what to
/// call it. Used by the page index, which would otherwise decode every blok on
/// the site to render a list of names.
public struct StoryOverview: Decodable, Sendable {
    public let component: String
    public let title: String?

    private enum CodingKeys: String, CodingKey {
        case component, title
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        component = container.cmsString(forKey: .component) ?? ""
        title = container.cmsString(forKey: .title)
    }
}

public extension StorySlug {
    /// Stories the page index deliberately leaves out.
    ///
    /// `config` is the settings story, not a page; `home` is the work index,
    /// which the first tab already is.
    static func isHiddenFromPageIndex(_ slug: String, component: String) -> Bool {
        slug == config || slug == home || component == "config" || component == "work"
    }
}

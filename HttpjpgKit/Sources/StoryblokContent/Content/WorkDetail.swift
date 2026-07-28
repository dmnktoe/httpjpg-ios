import Foundation
import StoryblokClient

/// A fully-loaded `work/*` story, ready to render.
///
/// Deliberately not `Sendable`: it carries a decoded `RichText` tree, which the
/// SDK does not vend as `Sendable`. It is produced on, and consumed by, the
/// main actor.
public struct WorkDetail: Identifiable {
    public let id: String
    public let slug: String
    public let fullSlug: String
    public let title: String
    public let details: RichTextNode?
    /// Flattened `details`, for share sheets and accessibility summaries.
    public let summary: String
    public let images: [StoryblokAsset]
    public let date: Date?
    public let dateEnd: Date?
    public let link: StoryblokLink?
    public let tags: [String]
    public let isDark: Bool
    public let body: [PortfolioBlok]

    public init(story: Story<WorkBlok>) {
        let content = story.content
        id = story.uuid.uuidString
        slug = story.slug
        fullSlug = story.fullSlug
        title = content.title ?? story.name
        details = content.details
        summary = extractPlainText(content.details, maxLength: 240)
        images = content.images.filter { !$0.isEmpty }
        date = StoryblokDate.parse(content.date)
        dateEnd = StoryblokDate.parse(content.dateEnd)
        link = content.link?.isEmpty == true ? nil : content.link
        tags = story.tagList
        isDark = content.isDark
        body = content.body
    }

    /// The canonical web URL for this piece, used by the share sheet.
    public func canonicalURL(siteOrigin: URL) -> URL {
        siteOrigin.appending(path: fullSlug)
    }
}

/// A generic `page` story (`home`, `cv`, `cookie-policy`, …).
public struct PageDocument: Identifiable {
    public let id: String
    public let slug: String
    public let title: String
    public let isDark: Bool
    public let body: [PortfolioBlok]

    public init(story: Story<PageBlok>) {
        id = story.uuid.uuidString
        slug = story.slug
        title = story.content.title ?? story.name
        isDark = story.content.isDark
        body = story.content.body
    }
}

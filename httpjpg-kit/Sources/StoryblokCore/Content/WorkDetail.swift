import Foundation
import StoryblokClient

public struct WorkDetail: Identifiable {
    public let id: String
    public let slug: String
    public let fullSlug: String
    public let title: String
    public let details: RichTextNode?

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

    public func canonicalURL(siteOrigin: URL) -> URL {
        siteOrigin.appending(path: fullSlug)
    }
}

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

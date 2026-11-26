import Foundation
import StoryblokClient

public struct FeedPost: Identifiable {
    public let id: String
    public let slug: String
    public let fullSlug: String
    public let blok: PostBlok

    public init(id: String, slug: String, fullSlug: String, blok: PostBlok) {
        self.id = id
        self.slug = slug
        self.fullSlug = fullSlug
        self.blok = blok
    }

    public func with(blok next: PostBlok) -> FeedPost {
        FeedPost(id: id, slug: slug, fullSlug: fullSlug, blok: next)
    }

    init(story: Story<PostBlok>) {
        self.init(
            id: story.uuid.uuidString,
            slug: story.slug,
            fullSlug: story.fullSlug,
            blok: story.content
        )
    }
}

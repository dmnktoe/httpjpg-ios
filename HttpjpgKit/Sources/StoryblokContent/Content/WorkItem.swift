import Foundation
import StoryblokClient

/// A row in the work index — the Swift port of `WorkItem` in
/// `apps/portfolio/lib/queries/work.ts`.
public struct WorkItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let slug: String
    public let fullSlug: String
    public let title: String
    /// Already run through ``ImageService/Preset`` — a thumbnail, not the original.
    public let thumbnailURL: URL?
    /// Raw asset URLs, still untransformed, so the card can size them to the
    /// device it is actually rendering on.
    public let imageFilenames: [String]
    public let isDraft: Bool
    public let isExternal: Bool
    public let externalURL: URL?
    public let date: Date?
    public let tags: [String]

    public init(
        id: String,
        slug: String,
        fullSlug: String,
        title: String,
        thumbnailURL: URL?,
        imageFilenames: [String],
        isDraft: Bool,
        isExternal: Bool,
        externalURL: URL?,
        date: Date?,
        tags: [String]
    ) {
        self.id = id
        self.slug = slug
        self.fullSlug = fullSlug
        self.title = title
        self.thumbnailURL = thumbnailURL
        self.imageFilenames = imageFilenames
        self.isDraft = isDraft
        self.isExternal = isExternal
        self.externalURL = externalURL
        self.date = date
        self.tags = tags
    }
}

public extension WorkItem {
    /// Maps a story straight off the CDN, mirroring `toWorkItem`.
    init(story: Story<WorkBlok>) {
        let content = story.content
        let externalURL = content.link?.href.flatMap(URL.init(string:))
        let filenames = content.images.images.compactMap(\.filename)

        self.init(
            id: story.uuid.uuidString,
            slug: story.slug,
            fullSlug: story.fullSlug,
            title: content.title ?? story.name,
            thumbnailURL: URL(string: ImageService.Preset.thumb(filenames.first)),
            imageFilenames: filenames,
            isDraft: story.firstPublishedAt == nil,
            isExternal: content.isExternalOnly,
            externalURL: externalURL,
            date: StoryblokDate.parse(content.date),
            tags: story.tagList
        )
    }
}

/// The two slices the header menu exposes, mirroring `getRecentWork`.
public struct WorkCollection: Sendable {
    public let projects: [WorkItem]
    public let websites: [WorkItem]

    public init(projects: [WorkItem], websites: [WorkItem]) {
        self.projects = projects
        self.websites = websites
    }

    public static let empty = WorkCollection(projects: [], websites: [])

    public func items(for variant: MenuLink.Variant) -> [WorkItem] {
        switch variant {
        case .projects: return projects
        case .websites: return websites
        }
    }
}

/// Slug conventions shared with `apps/portfolio/lib/storyblok-slugs.ts`.
public enum StorySlug {
    public static let config = "config"
    public static let home = "home"
    public static let workPrefix = "work/"

    /// `true` for `work/<slug>` and nothing deeper — folder index pages and
    /// nested stories don't belong in the work list.
    public static func isDirectWork(_ fullSlug: String) -> Bool {
        fullSlug.hasPrefix(workPrefix) && fullSlug.split(separator: "/").count == 2
    }
}

/// Tag names Storyblok uses to split the index.
enum WorkTag {
    static let projects = "Projects"
    static let websites = "Websites"
}

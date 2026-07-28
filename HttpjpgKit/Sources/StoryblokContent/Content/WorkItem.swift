import Foundation
import StoryblokClient

/// A row in the work index — the Swift port of `WorkItem` in
/// `apps/portfolio/lib/queries/work.ts`.
public struct WorkItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let slug: String
    public let fullSlug: String
    public let title: String
    /// The story's `description` rich text, flattened. Card excerpts need
    /// plain text, and carrying it on the item saves a second fetch per row.
    public let summary: String
    /// Already run through ``ImageService/Preset`` — a thumbnail, not the original.
    public let thumbnailURL: URL?
    /// Raw *image* asset URLs, untransformed. Kept image-only for the widget
    /// and the thumbnail, which cannot show a clip.
    public let imageFilenames: [String]
    /// Every media asset in CMS order, clips included — the card carousel
    /// renders this, the same list the web card feeds its slideshow.
    public let media: [WorkMedia]
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
        summary: String = "",
        thumbnailURL: URL?,
        imageFilenames: [String],
        media: [WorkMedia] = [],
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
        self.summary = summary
        self.thumbnailURL = thumbnailURL
        self.imageFilenames = imageFilenames
        self.media = media.isEmpty ? imageFilenames.map { WorkMedia(filename: $0, isVideo: false) } : media
        self.isDraft = isDraft
        self.isExternal = isExternal
        self.externalURL = externalURL
        self.date = date
        self.tags = tags
    }
}

/// One entry in a story's media strip — a still or a clip, in CMS order.
public struct WorkMedia: Hashable, Sendable {
    public let filename: String
    public let isVideo: Bool

    public init(filename: String, isVideo: Bool) {
        self.filename = filename
        self.isVideo = isVideo
    }
}

public extension WorkItem {
    /// Maps a story straight off the CDN, mirroring `toWorkItem`.
    init(story: Story<WorkBlok>) {
        let content = story.content
        let externalURL = content.link?.href.flatMap(URL.init(string:))
        let filenames = content.images.images.compactMap(\.filename)
        // Clips stay in, in CMS order — the web card's slideshow plays them,
        // and dropping them here was why card videos never appeared.
        let media = content.images
            .filter { !$0.isEmpty }
            .compactMap { asset in
                asset.filename.map { WorkMedia(filename: $0, isVideo: asset.isVideo) }
            }

        self.init(
            id: story.uuid.uuidString,
            slug: story.slug,
            fullSlug: story.fullSlug,
            title: content.title ?? story.name,
            summary: extractPlainText(content.details, maxLength: 280),
            thumbnailURL: URL(string: ImageService.Preset.thumb(filenames.first)),
            imageFilenames: filenames,
            media: media,
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

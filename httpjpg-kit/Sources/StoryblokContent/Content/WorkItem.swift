import Foundation
import StoryblokClient

public struct WorkItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let slug: String
    public let fullSlug: String
    public let title: String

    public let summary: String

    public let thumbnailURL: URL?

    public let imageFilenames: [String]

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

public struct WorkMedia: Hashable, Sendable {
    public let filename: String
    public let isVideo: Bool

    public init(filename: String, isVideo: Bool) {
        self.filename = filename
        self.isVideo = isVideo
    }
}

public extension WorkItem {
    init(story: Story<WorkBlok>) {
        let content = story.content
        let externalURL = content.link?.href.flatMap(URL.init(string:))
        let filenames = content.images.images.compactMap(\.filename)

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

public enum StorySlug {
    public static let config = "config"
    public static let home = "home"

    /// The picture feed — a page of loose image bloks rather than a work.
    public static let feed = "feed-xml_html"
    public static let workPrefix = "work/"

    public static func isDirectWork(_ fullSlug: String) -> Bool {
        fullSlug.hasPrefix(workPrefix) && fullSlug.split(separator: "/").count == 2
    }
}

enum WorkTag {
    static let projects = "Projects"
    static let websites = "Websites"
}

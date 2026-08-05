import SwiftUI

private struct StoryblokConfigurationKey: EnvironmentKey {
    static let defaultValue = StoryblokConfiguration(accessToken: "")
}

public extension EnvironmentValues {
    var storyblokConfiguration: StoryblokConfiguration {
        get { self[StoryblokConfigurationKey.self] }
        set { self[StoryblokConfigurationKey.self] = newValue }
    }
}

private struct ContentClientKey: EnvironmentKey {
    static let defaultValue: ContentClient? = nil
}

public extension EnvironmentValues {
    var contentClient: ContentClient? {
        get { self[ContentClientKey.self] }
        set { self[ContentClientKey.self] = newValue }
    }
}

public struct WorkRoute: Hashable, Identifiable, Sendable {
    public let slug: String
    public let title: String

    /// The work's external link, when the index payload already knows it —
    /// lets the detail toolbar show the preview button from the first frame
    /// instead of after the detail loads.
    public let previewURL: URL?

    public var id: String { slug }

    public init(slug: String, title: String, previewURL: URL? = nil) {
        self.slug = slug
        self.title = title
        self.previewURL = previewURL
    }

    public init(item: WorkItem) {
        self.init(slug: item.slug, title: item.title, previewURL: item.externalURL)
    }
}

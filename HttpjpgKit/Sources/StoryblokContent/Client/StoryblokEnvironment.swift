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

    public var id: String { slug }

    public init(slug: String, title: String) {
        self.slug = slug
        self.title = title
    }

    public init(item: WorkItem) {
        self.init(slug: item.slug, title: item.title)
    }
}

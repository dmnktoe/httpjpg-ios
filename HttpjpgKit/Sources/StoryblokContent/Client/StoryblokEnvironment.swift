import SwiftUI

/// The active Storyblok configuration, so blok renderers can resolve internal
/// links without being handed the client.
private struct StoryblokConfigurationKey: EnvironmentKey {
    static let defaultValue = StoryblokConfiguration(accessToken: "")
}

public extension EnvironmentValues {
    var storyblokConfiguration: StoryblokConfiguration {
        get { self[StoryblokConfigurationKey.self] }
        set { self[StoryblokConfigurationKey.self] = newValue }
    }
}

/// The live client, for the rare blok that has to fetch for itself —
/// `work_list` resolving its relation UUIDs. Optional so previews and tests
/// can render bloks without standing up networking.
private struct ContentClientKey: EnvironmentKey {
    static let defaultValue: ContentClient? = nil
}

public extension EnvironmentValues {
    var contentClient: ContentClient? {
        get { self[ContentClientKey.self] }
        set { self[ContentClientKey.self] = newValue }
    }
}

/// A destination inside the work section.
///
/// Declared here rather than in the feature layer so blok renderers — which
/// live alongside the content models — can push routes without depending on
/// the screens that resolve them.
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

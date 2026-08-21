import Foundation

/// The container the app, the widget extension and the App Intents process share
/// their caches through, so a story the app already fetched does not travel a
/// second time for a widget timeline.
///
/// Every lookup is optional on purpose: the entitlement is missing in unit
/// tests, in previews and on watchOS, and callers fall back to a per-process
/// cache rather than losing caching altogether.
public enum AppGroup {
    public enum InfoPlistKey {
        public static let identifier = "APP_GROUP_IDENTIFIER"
    }

    public enum CacheName {
        public static let content = "storyblok"
        public static let images = "images"
    }

    public static let defaultIdentifier = "group.com.yl33ly.httpjpg"

    public static func identifier(_ bundle: Bundle = .main) -> String {
        guard let value = bundle.object(forInfoDictionaryKey: InfoPlistKey.identifier) as? String else {
            return defaultIdentifier
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultIdentifier : trimmed
    }

    public static func containerURL(_ bundle: Bundle = .main) -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier(bundle))
    }

    /// A cache directory inside the group container, created on first use.
    /// `nil` whenever the container is out of reach or cannot be written to.
    public static func cachesURL(_ name: String, bundle: Bundle = .main) -> URL? {
        guard let container = containerURL(bundle) else { return nil }

        let directory = container.appending(path: "Caches/\(name)", directoryHint: .isDirectory)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            return nil
        }
        return directory
    }
}

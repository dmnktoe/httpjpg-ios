import Foundation

/// The URL contract between the widget and the app.
///
/// Tapping a widget opens `httpjpg://work/<slug>`; the app parses it back into
/// a route. Declared here, in the module both sides link, so the two halves
/// cannot drift.
public enum WidgetDeepLink {
    public static let scheme = "httpjpg"
    private static let workHost = "work"

    public static func work(slug: String) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = workHost
        components.path = "/" + slug
        return components.url
    }

    /// Returns the work slug a URL points at, or `nil` if it points elsewhere.
    public static func workSlug(from url: URL) -> String? {
        guard url.scheme == scheme, url.host == workHost else { return nil }
        let slug = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return slug.isEmpty ? nil : slug
    }
}

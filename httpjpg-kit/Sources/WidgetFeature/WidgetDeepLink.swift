import Foundation

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

    public static func workSlug(from url: URL) -> String? {
        guard url.scheme == scheme, url.host == workHost else { return nil }
        let slug = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return slug.isEmpty ? nil : slug
    }
}

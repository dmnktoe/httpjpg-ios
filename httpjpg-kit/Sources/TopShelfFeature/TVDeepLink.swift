import Foundation

public enum TVDeepLink {
    static let scheme = "httpjpg"
    static let workHost = "work"

    public static func work(slug: String) -> URL? {
        guard !slug.isEmpty else { return nil }
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

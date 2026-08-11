import Foundation

public enum WidgetDeepLink {
    public static let scheme = "httpjpg"

    public enum Destination: Equatable, Sendable {
        case work(slug: String)
        case workIndex
        case page(slug: String)
        case info
    }

    private static let workHost = "work"
    private static let pageHost = "page"
    private static let infoHost = "info"

    public static func work(slug: String) -> URL? {
        guard !slug.isEmpty else { return nil }
        return url(host: workHost, slug: slug)
    }

    public static func page(slug: String) -> URL? {
        guard !slug.isEmpty else { return nil }
        return url(host: pageHost, slug: slug)
    }

    public static var workIndex: URL? {
        url(host: workHost, slug: nil)
    }

    public static var info: URL? {
        url(host: infoHost, slug: nil)
    }

    public static func destination(from url: URL) -> Destination? {
        guard url.scheme == scheme, let host = url.host else { return nil }
        let slug = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        switch (host, slug.isEmpty) {
        case (workHost, false): return .work(slug: slug)
        case (workHost, true): return .workIndex
        case (pageHost, false): return .page(slug: slug)
        case (infoHost, true): return .info
        default: return nil
        }
    }

    private static func url(host: String, slug: String?) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        if let slug, !slug.isEmpty {
            components.path = "/" + slug
        }
        return components.url
    }
}

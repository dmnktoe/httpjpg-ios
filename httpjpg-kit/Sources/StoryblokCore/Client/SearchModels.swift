import Foundation

/// One hit from `GET /api/search`. Mirrors the web `SearchResult` / ranking shape.
public struct SearchHit: Decodable, Hashable, Identifiable, Sendable {
    public enum Kind: String, Decodable, Sendable, Hashable {
        case work
        case page
    }

    public let id: String
    public let title: String
    public let href: String
    public let kind: Kind
    public let excerpt: String?

    private enum CodingKeys: String, CodingKey {
        case id, title, href, kind, excerpt
    }

    public init(
        id: String,
        title: String,
        href: String,
        kind: Kind,
        excerpt: String? = nil
    ) {
        self.id = id
        self.title = title
        self.href = href
        self.kind = kind
        self.excerpt = excerpt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = container.cmsString(forKey: .id) ?? UUID().uuidString
        title = container.cmsString(forKey: .title) ?? ""
        href = container.cmsString(forKey: .href) ?? ""
        kind = container.cmsString(forKey: .kind).flatMap(Kind.init(rawValue:)) ?? .page
        excerpt = container.cmsString(forKey: .excerpt)
    }
}

public struct SearchResponse: Decodable, Sendable {
    public let results: [SearchHit]
    public let suggestions: [String]

    private enum CodingKeys: String, CodingKey {
        case results, suggestions
    }

    public init(results: [SearchHit] = [], suggestions: [String] = []) {
        self.results = results
        self.suggestions = suggestions
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        results = container.cmsArray(SearchHit.self, forKey: .results)
        suggestions = container.cmsArray(String.self, forKey: .suggestions)
    }
}

/// Slim citation the ask stream hands the palette before the answer tokens.
public struct AskSource: Decodable, Hashable, Sendable {
    public let title: String
    public let href: String
    public let kind: SearchHit.Kind?

    private enum CodingKeys: String, CodingKey {
        case title, href, kind
    }

    public init(title: String, href: String, kind: SearchHit.Kind? = nil) {
        self.title = title
        self.href = href
        self.kind = kind
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = container.cmsString(forKey: .title) ?? ""
        href = container.cmsString(forKey: .href) ?? ""
        kind = container.cmsString(forKey: .kind).flatMap(SearchHit.Kind.init(rawValue:))
    }
}

/// Derived navigate offer from a finished ask answer — same-origin site paths only.
public struct AskNavigateAction: Hashable, Sendable {
    public let href: String
    public let title: String
    public let kind: SearchHit.Kind

    public init(href: String, title: String, kind: SearchHit.Kind) {
        self.href = href
        self.title = title
        self.kind = kind
    }

    /// Re-validates the action the server derived: site-relative, not protocol-relative.
    public static func parse(_ value: Any?) -> AskNavigateAction? {
        guard let object = value as? [String: Any] else { return nil }
        guard object["type"] as? String == "navigate" else { return nil }
        guard let href = object["href"] as? String,
              href.hasPrefix("/"),
              !href.hasPrefix("//")
        else { return nil }
        guard let title = object["title"] as? String, !title.isEmpty else { return nil }
        let kind = (object["kind"] as? String).flatMap(SearchHit.Kind.init(rawValue:)) ?? .page
        return AskNavigateAction(href: href, title: title, kind: kind)
    }
}

/// One NDJSON line from `POST /api/ask`.
public enum AskStreamEvent: Sendable, Equatable {
    case sources([AskSource])
    case delta(String)
    case action(AskNavigateAction)
    case error(String)

    public static func parse(_ line: String) -> AskStreamEvent? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let data = trimmed.data(using: .utf8) else { return nil }

        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let type = object["type"] as? String
        else { return nil }

        switch type {
        case "sources":
            let raw = object["sources"] as? [[String: Any]] ?? []
            let sources = raw.compactMap { entry -> AskSource? in
                guard let title = entry["title"] as? String, let href = entry["href"] as? String else {
                    return nil
                }
                let kind = (entry["kind"] as? String).flatMap(SearchHit.Kind.init(rawValue:))
                return AskSource(title: title, href: href, kind: kind)
            }
            return .sources(sources)
        case "delta":
            guard let text = object["text"] as? String else { return nil }
            return .delta(text)
        case "action":
            guard let action = AskNavigateAction.parse(object["action"]) else { return nil }
            return .action(action)
        case "error":
            let message = object["error"] as? String ?? "ai_failed"
            return .error(message)
        default:
            return nil
        }
    }
}

public enum SiteAPIError: Error, Equatable, Sendable {
    case badURL
    case http(status: Int)
    /// Ask is not configured on the deployment (no Groq key) — search still works.
    case askUnavailable
    case transport(String)
}

/// Turns a search / ask `href` into an in-app destination.
public enum SearchDestination: Equatable, Sendable {
    case work(slug: String, title: String)
    case page(slug: String, title: String)
    case workIndex
    case external(URL)

    public static func resolve(href: String, title: String) -> SearchDestination? {
        let trimmed = href.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(),
           scheme == "http" || scheme == "https"
        {
            return .external(url)
        }

        let path = trimmed.hasPrefix("/") ? String(trimmed.dropFirst()) : trimmed
        if path.isEmpty || path == StorySlug.home {
            return .workIndex
        }

        if path.hasPrefix(StorySlug.workPrefix) {
            let slug = String(path.dropFirst(StorySlug.workPrefix.count))
                .split(separator: "/")
                .first
                .map(String.init) ?? ""
            guard !slug.isEmpty else { return nil }
            return .work(slug: slug, title: title.isEmpty ? slug : title)
        }

        let slug = path.split(separator: "/").first.map(String.init) ?? path
        guard !slug.isEmpty else { return nil }
        return .page(slug: slug, title: title.isEmpty ? slug : title)
    }
}

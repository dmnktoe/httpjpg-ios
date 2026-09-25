import Foundation
import StoryblokCore

public enum WidgetDeepLink {
    public static let scheme = "httpjpg"

    public enum Destination: Equatable, Sendable {
        case work(slug: String)
        case workIndex
        case page(slug: String)
        case info
        case play(AudioTrack)
        case search(query: String?)
    }

    private static let workHost = "work"
    private static let pageHost = "page"
    private static let infoHost = "info"
    private static let playHost = "play"
    private static let searchHost = "search"

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

    public static func search(query: String? = nil) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = searchHost
        if let query, !query.isEmpty {
            components.queryItems = [URLQueryItem(name: "q", value: query)]
        }
        return components.url
    }

    public static func play(_ track: AudioTrack) -> URL? {
        guard !track.id.isEmpty else { return nil }
        var components = URLComponents()
        components.scheme = scheme
        components.host = playHost
        components.path = "/" + track.id
        var items = [
            URLQueryItem(name: "title", value: track.title),
            URLQueryItem(name: "src", value: track.streamURL.absoluteString),
        ]
        if let artist = track.artist, !artist.isEmpty {
            items.append(URLQueryItem(name: "artist", value: artist))
        }
        if let artwork = track.artworkURL {
            items.append(URLQueryItem(name: "artwork", value: artwork.absoluteString))
        }
        components.queryItems = items
        return components.url
    }

    public static func destination(from url: URL) -> Destination? {
        guard url.scheme == scheme, let host = url.host else { return nil }
        let slug = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        switch (host, slug.isEmpty) {
        case (workHost, false): return .work(slug: slug)
        case (workHost, true): return .workIndex
        case (pageHost, false): return .page(slug: slug)
        case (infoHost, true): return .info
        case (searchHost, true): return .search(query: searchQuery(from: url))
        case (playHost, false): return playDestination(from: url, id: slug)
        default: return nil
        }
    }

    private static func searchQuery(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        let value = components.queryItems?.first(where: { $0.name == "q" })?.value
        guard let value, !value.isEmpty else { return nil }
        return value
    }

    private static func playDestination(from url: URL, id: String) -> Destination? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        var values: [String: String] = [:]
        for item in components.queryItems ?? [] {
            guard let value = item.value, !value.isEmpty else { continue }
            values[item.name] = value
        }
        guard let src = values["src"], let streamURL = URL(string: src),
              streamURL.scheme == "https" || streamURL.scheme == "http"
        else { return nil }
        let title = values["title"].flatMap { $0.isEmpty ? nil : $0 } ?? "untitled"
        return .play(
            AudioTrack(
                id: id,
                title: title,
                artist: values["artist"],
                streamURL: streamURL,
                artworkURL: values["artwork"].flatMap(URL.init(string:))
            )
        )
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

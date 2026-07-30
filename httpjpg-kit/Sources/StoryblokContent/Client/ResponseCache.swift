import Foundation

/// A fixed freshness window on top of `URLCache`.
///
/// Freshness is decided by the stamp written on store, not by the response headers:
/// Storyblok answers through a CDN, so `date` is the edge's own and only means
/// something once unpicked together with `age`.
final class ResponseCache: @unchecked Sendable {
    /// Carried as a header because `URLCache` persists those to disk — `userInfo` it drops.
    static let stampHeader = "X-Httpjpg-Stored-At"

    let ttl: TimeInterval

    private let cache: URLCache

    init(cache: URLCache, ttl: TimeInterval) {
        self.cache = cache
        self.ttl = ttl
    }

    /// The stored body, or `nil` when nothing was stored or the entry aged out.
    func data(for request: URLRequest, now: Date = Date()) -> Data? {
        guard let cached = cache.cachedResponse(for: request),
              let response = cached.response as? HTTPURLResponse,
              let stamp = response.value(forHTTPHeaderField: Self.stampHeader),
              let storedAt = TimeInterval(stamp)
        else { return nil }

        // Rejecting negative ages too: a clock that jumped backwards would otherwise
        // pin an entry as fresh until it jumps forward again.
        let age = now.timeIntervalSince1970 - storedAt
        guard age >= 0, age < ttl else { return nil }

        return cached.data
    }

    func store(_ data: Data, response: HTTPURLResponse, for request: URLRequest, now: Date = Date()) {
        guard let url = response.url else { return }

        var headers = response.allHeaderFields as? [String: String] ?? [:]
        headers[Self.stampHeader] = String(now.timeIntervalSince1970)

        guard let stamped = HTTPURLResponse(
            url: url,
            statusCode: response.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        ) else { return }

        cache.storeCachedResponse(
            CachedURLResponse(response: stamped, data: data, storagePolicy: .allowed),
            for: request
        )
    }
}

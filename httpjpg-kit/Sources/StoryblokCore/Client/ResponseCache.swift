import Foundation

final class ResponseCache: @unchecked Sendable {
    static let stampHeader = "X-Httpjpg-Stored-At"

    let ttl: TimeInterval

    private let cache: URLCache

    init(cache: URLCache, ttl: TimeInterval) {
        self.cache = cache
        self.ttl = ttl
    }

    func data(for request: URLRequest, allowsStale: Bool = false, now: Date = Date()) -> Data? {
        guard let cached = cache.cachedResponse(for: request),
              let response = cached.response as? HTTPURLResponse,
              let stamp = response.value(forHTTPHeaderField: Self.stampHeader),
              let storedAt = TimeInterval(stamp)
        else { return nil }

        let age = now.timeIntervalSince1970 - storedAt
        guard age >= 0, allowsStale || age < ttl else { return nil }

        return cached.data
    }

    func removeAll() {
        cache.removeAllCachedResponses()
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

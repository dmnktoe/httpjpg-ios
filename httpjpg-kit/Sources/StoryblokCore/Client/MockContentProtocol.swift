import Foundation

final class MockContentProtocol: URLProtocol {
    nonisolated(unsafe) private static var isRegistered = false

    private static let lock = NSLock()

    static func install() {
        lock.lock()
        defer { lock.unlock() }
        guard !isRegistered else { return }
        isRegistered = true
        URLProtocol.registerClass(MockContentProtocol.self)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        MockContentFixtures.handles(request.url)
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: ContentError.transport("missing url"))
            return
        }

        let fixture = MockContentFixtures.response(for: url)
        let response = HTTPURLResponse(
            url: url,
            statusCode: fixture.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": fixture.contentType]
        )

        if let response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        client?.urlProtocol(self, didLoad: fixture.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

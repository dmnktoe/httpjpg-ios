import XCTest

@testable import StoryblokContent

final class ResponseCacheTests: XCTestCase {
    private let ttl: TimeInterval = 60 * 60
    private let now = Date(timeIntervalSince1970: 1_700_000_000)
    private let body = Data(#"{"stories":[]}"#.utf8)

    private var store: URLCache!
    private var cache: ResponseCache!

    override func setUp() {
        super.setUp()
        store = URLCache(memoryCapacity: 512 * 1024, diskCapacity: 0)
        cache = ResponseCache(cache: store, ttl: ttl)
    }

    override func tearDown() {
        cache = nil
        store = nil
        super.tearDown()
    }

    func testMissesWhenNothingWasStored() {
        XCTAssertNil(cache.data(for: request("nothing-stored"), now: now))
    }

    func testServesTheStoredBodyInsideTheWindow() {
        let request = request("inside-window")
        cache.store(body, response: response(for: request), for: request, now: now)

        XCTAssertEqual(cache.data(for: request, now: now.addingTimeInterval(ttl - 1)), body)
    }

    func testDropsTheEntryOnceTheWindowHasPassed() {
        let request = request("past-window")
        cache.store(body, response: response(for: request), for: request, now: now)

        XCTAssertNil(cache.data(for: request, now: now.addingTimeInterval(ttl + 1)))
    }

    func testDropsAnEntryStampedInTheFuture() {
        let request = request("clock-jumped-back")
        cache.store(body, response: response(for: request), for: request, now: now)

        XCTAssertNil(cache.data(for: request, now: now.addingTimeInterval(-60)))
    }

    func testStoringAgainMovesTheWindowForward() {
        let request = request("stored-twice")
        cache.store(body, response: response(for: request), for: request, now: now)

        let later = now.addingTimeInterval(ttl - 1)
        cache.store(body, response: response(for: request), for: request, now: later)

        XCTAssertEqual(cache.data(for: request, now: later.addingTimeInterval(ttl - 1)), body)
    }

    func testIgnoresAnEntryThatCarriesNoStamp() {
        let request = request("unstamped")
        store.storeCachedResponse(
            CachedURLResponse(response: response(for: request), data: body, storagePolicy: .allowed),
            for: request
        )

        XCTAssertNil(cache.data(for: request, now: now))
    }

    private func request(_ name: String) -> URLRequest {
        URLRequest(url: URL(string: "https://api.storyblok.com/v2/cdn/\(name)")!)
    }

    private func response(for request: URLRequest) -> HTTPURLResponse {
        HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
    }
}

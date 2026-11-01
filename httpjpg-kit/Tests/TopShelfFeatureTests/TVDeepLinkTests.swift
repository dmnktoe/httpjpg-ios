import XCTest

@testable import TopShelfFeature

final class TVDeepLinkTests: XCTestCase {
    func testWorkLinkRoundTrips() throws {
        let url = try XCTUnwrap(TVDeepLink.work(slug: "nachtbus"))

        XCTAssertEqual(url.absoluteString, "httpjpg://work/nachtbus")
        XCTAssertEqual(TVDeepLink.workSlug(from: url), "nachtbus")
    }

    func testEmptySlugMakesNoLink() {
        XCTAssertNil(TVDeepLink.work(slug: ""))
    }

    func testOtherRoutesAreNotWorks() throws {
        XCTAssertNil(TVDeepLink.workSlug(from: try XCTUnwrap(URL(string: "httpjpg://work"))))
        XCTAssertNil(TVDeepLink.workSlug(from: try XCTUnwrap(URL(string: "httpjpg://page/about"))))
        XCTAssertNil(TVDeepLink.workSlug(from: try XCTUnwrap(URL(string: "https://work/nachtbus"))))
    }
}

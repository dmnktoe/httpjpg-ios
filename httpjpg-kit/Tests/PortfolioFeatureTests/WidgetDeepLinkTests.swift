import WidgetFeature
import XCTest

final class WidgetDeepLinkTests: XCTestCase {
    func testAWorkLinkRoundTrips() throws {
        let url = try XCTUnwrap(WidgetDeepLink.work(slug: "atlas-der-nebenstrassen"))

        XCTAssertEqual(url.absoluteString, "httpjpg://work/atlas-der-nebenstrassen")
        XCTAssertEqual(
            WidgetDeepLink.destination(from: url),
            .work(slug: "atlas-der-nebenstrassen")
        )
    }

    func testAPageLinkRoundTrips() throws {
        let url = try XCTUnwrap(WidgetDeepLink.page(slug: "feed-xml_html"))

        XCTAssertEqual(url.absoluteString, "httpjpg://page/feed-xml_html")
        XCTAssertEqual(WidgetDeepLink.destination(from: url), .page(slug: "feed-xml_html"))
    }

    func testBareHostsAreTabRoots() throws {
        XCTAssertEqual(
            WidgetDeepLink.destination(from: try XCTUnwrap(WidgetDeepLink.workIndex)),
            .workIndex
        )
        XCTAssertEqual(
            WidgetDeepLink.destination(from: try XCTUnwrap(WidgetDeepLink.info)),
            .info
        )
    }

    func testATrailingSlashStillReadsAsATabRoot() throws {
        let url = try XCTUnwrap(URL(string: "httpjpg://work/"))

        XCTAssertEqual(WidgetDeepLink.destination(from: url), .workIndex)
    }

    func testTheInfoTabTakesNoSlug() throws {
        let url = try XCTUnwrap(URL(string: "httpjpg://info/imprint"))

        XCTAssertNil(WidgetDeepLink.destination(from: url))
    }

    func testForeignSchemesAndHostsAreRejected() throws {
        XCTAssertNil(
            WidgetDeepLink.destination(from: try XCTUnwrap(URL(string: "https://work/atlas")))
        )
        XCTAssertNil(
            WidgetDeepLink.destination(from: try XCTUnwrap(URL(string: "httpjpg://shop/atlas")))
        )
    }
}

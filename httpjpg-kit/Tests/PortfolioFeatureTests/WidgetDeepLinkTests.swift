import StoryblokCore
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

    func testAnEmptySlugBuildsNoDocumentLink() {
        XCTAssertNil(WidgetDeepLink.work(slug: ""))
        XCTAssertNil(WidgetDeepLink.page(slug: ""))
    }

    func testForeignSchemesAndHostsAreRejected() throws {
        XCTAssertNil(
            WidgetDeepLink.destination(from: try XCTUnwrap(URL(string: "https://work/atlas")))
        )
        XCTAssertNil(
            WidgetDeepLink.destination(from: try XCTUnwrap(URL(string: "httpjpg://shop/atlas")))
        )
    }

    func testAPlayLinkRoundTripsTheTrack() throws {
        let track = AudioTrack(
            id: "139e6c5f-4c19-4878-9ec3-c195ff071215",
            title: "mega mashup",
            artist: "te3shay",
            streamURL: try XCTUnwrap(URL(string: "https://cdn.httpjpg.com/music/MEGA%20MASHUP.wav")),
            artworkURL: try XCTUnwrap(URL(string: "https://a.storyblok.com/f/281211/811x811/dffa91ee4a/img_4103.JPG"))
        )

        let url = try XCTUnwrap(WidgetDeepLink.play(track))
        XCTAssertEqual(WidgetDeepLink.destination(from: url), .play(track))
    }

    func testAPlayLinkWithoutAStreamIsDropped() throws {
        XCTAssertNil(
            WidgetDeepLink.destination(
                from: try XCTUnwrap(URL(string: "httpjpg://play/track-1?title=untitled"))
            )
        )
    }
}

import Foundation
import XCTest

@testable import PortfolioFeature

final class FeaturedChromeTintTests: XCTestCase {
    func testNormalizesProtocolRelativeStoryblokURLs() throws {
        let raw = try XCTUnwrap(URL(string: "//a.storyblok.com/f/123/image.jpg"))
        let normalized = try XCTUnwrap(FeaturedChromeTint.normalized(raw))
        XCTAssertEqual(normalized.scheme, "https")
        XCTAssertEqual(normalized.host, "a.storyblok.com")
    }

    func testKeepsAbsoluteHTTPS() throws {
        let raw = try XCTUnwrap(URL(string: "https://a.storyblok.com/f/123/image.jpg"))
        XCTAssertEqual(FeaturedChromeTint.normalized(raw), raw)
    }

    func testRejectsFileURLs() throws {
        XCTAssertNil(FeaturedChromeTint.normalized(URL(fileURLWithPath: "/tmp/x.jpg")))
    }
}

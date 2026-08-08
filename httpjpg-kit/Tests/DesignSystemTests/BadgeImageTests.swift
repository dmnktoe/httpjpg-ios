import SVGView
import XCTest

@testable import DesignSystem

final class BadgeImageTests: XCTestCase {
    private let shieldsBadge = """
    <svg xmlns="http://www.w3.org/2000/svg" width="104" height="20" viewBox="0 0 104 20">
      <rect width="104" height="20" fill="#555"/>
    </svg>
    """

    func testSniffsSVGWhenTheServerMislabelsIt() {
        XCTAssertTrue(BadgeImage.looksLikeSVG(Data(shieldsBadge.utf8)))

        let withProlog = #"<?xml version="1.0"?>\#n<svg width="10" height="10"></svg>"#
        XCTAssertTrue(BadgeImage.looksLikeSVG(Data(withProlog.utf8)))
    }

    func testDoesNotMistakeBitmapBytesForSVG() {
        // PNG magic number followed by IHDR.
        let png = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D])
        XCTAssertFalse(BadgeImage.looksLikeSVG(png))
        XCTAssertFalse(BadgeImage.looksLikeSVG(Data()))
        XCTAssertFalse(BadgeImage.looksLikeSVG(Data("plain text".utf8)))
    }

    func testReadsTheAspectRatioOffTheParsedViewport() throws {
        let node = try XCTUnwrap(
            SVGParser.parse(data: Data(shieldsBadge.utf8)),
            "SVGView must parse a shields-shaped badge"
        )
        XCTAssertEqual(BadgeImage.aspectRatio(of: node), 104.0 / 20.0, accuracy: 0.01)
    }

    func testFallsBackWhenTheViewportHasNoUsableSize() throws {
        let degenerate = #"<svg xmlns="http://www.w3.org/2000/svg" width="0" height="0"></svg>"#
        let node = try XCTUnwrap(SVGParser.parse(data: Data(degenerate.utf8)))
        XCTAssertEqual(
            BadgeImage.aspectRatio(of: node),
            BadgeImage.placeholderAspectRatio,
            "a zero-sized viewport must not produce a divide-by-zero ratio"
        )
    }
}

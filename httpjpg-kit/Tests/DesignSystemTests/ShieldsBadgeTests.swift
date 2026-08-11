import XCTest

@testable import DesignSystem

final class ShieldsBadgeTests: XCTestCase {
    private let realBadge = """
    <svg xmlns="http://www.w3.org/2000/svg" width="96" height="20" role="img" aria-label="Version: v1.2.1">\
    <title>Version: v1.2.1</title><filter id="blur"><feGaussianBlur stdDeviation="16"/></filter>\
    <linearGradient id="s" x2="0" y2="100%"><stop offset="0" stop-color="#bbb" stop-opacity=".1"/>\
    <stop offset="1" stop-opacity=".1"/></linearGradient><clipPath id="r"><rect width="96" height="20" rx="3"/></clipPath>\
    <g clip-path="url(#r)"><rect width="51" height="20" fill="#1d1d1b"/><rect x="51" width="45" height="20" fill="#d20515"/>\
    <rect width="96" height="20" fill="url(#s)"/></g><g fill="#fff" text-anchor="middle" \
    font-family="Verdana,Geneva,DejaVu Sans,sans-serif" text-rendering="geometricPrecision" font-size="110">\
    <g transform="scale(.1)"><g aria-hidden="true" fill="#010101">\
    <text x="265" y="150" fill-opacity=".8" filter="url(#blur)" textLength="410">Version</text>\
    <text x="265" y="150" fill-opacity=".3" textLength="410">Version</text></g>\
    <text x="265" y="140" textLength="410">Version</text></g><g transform="scale(.1)">\
    <g aria-hidden="true" fill="#010101"><text x="725" y="150" fill-opacity=".8" filter="url(#blur)" textLength="350">v1.2.1</text>\
    <text x="725" y="150" fill-opacity=".3" textLength="350">v1.2.1</text></g>\
    <text x="725" y="140" textLength="350">v1.2.1</text></g></g></svg>
    """

    func testReadsBothSegmentsOffARealBadge() throws {
        let badge = try XCTUnwrap(ShieldsBadge.parse(Data(realBadge.utf8)))
        XCTAssertEqual(
            badge.segments,
            [
                ShieldsBadge.Segment(text: "Version", color: "#1d1d1b"),
                ShieldsBadge.Segment(text: "v1.2.1", color: "#d20515"),
            ],
            "the shadow copies and the gloss rect must not become segments of their own"
        )
    }

    func testReadsASingleSegmentBadge() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="52" height="20"><clipPath id="r">\
        <rect width="52" height="20" rx="3"/></clipPath><g clip-path="url(#r)">\
        <rect width="52" height="20" fill="#4c1"/></g><g fill="#fff" font-size="110">\
        <g transform="scale(.1)"><text x="260" y="150" fill-opacity=".3">passing</text>\
        <text x="260" y="140">passing</text></g></g></svg>
        """
        let badge = try XCTUnwrap(ShieldsBadge.parse(Data(svg.utf8)))
        XCTAssertEqual(badge.segments, [ShieldsBadge.Segment(text: "passing", color: "#4c1")])
    }

    func testDecodesEscapedText() throws {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg"><rect width="60" height="20" fill="#555"/>\
        <g font-size="110"><g transform="scale(.1)"><text x="10" y="140">R&amp;D &lt;3</text></g></g></svg>
        """
        let badge = try XCTUnwrap(ShieldsBadge.parse(Data(svg.utf8)))
        XCTAssertEqual(badge.segments.first?.text, "R&D <3")
    }

    func testBailsOutWhenTextAndColoursDoNotPairUp() {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg"><rect width="20" height="20" fill="#555"/>\
        <rect x="20" width="40" height="20" fill="#4c1"/><g font-size="110">\
        <g transform="scale(.1)"><text x="10" y="140">only</text></g></g></svg>
        """
        XCTAssertNil(ShieldsBadge.parse(Data(svg.utf8)))
    }

    func testLeavesUnrelatedArtworkToTheVectorRenderer() {
        let diagram = """
        <svg xmlns="http://www.w3.org/2000/svg" width="120" height="60">\
        <rect width="120" height="60" fill="#eeeeee"/>\
        <text x="10" y="35" font-size="14">Node</text></svg>
        """
        XCTAssertNil(ShieldsBadge.parse(Data(diagram.utf8)))
    }

    func testIgnoresArtworkItIsNotMeantToRedraw() {
        XCTAssertNil(ShieldsBadge.parse(Data()))
        XCTAssertNil(
            ShieldsBadge.parse(Data(#"<svg xmlns="http://www.w3.org/2000/svg"><path d="M0 0h8v8H0z"/></svg>"#.utf8))
        )
        XCTAssertNil(ShieldsBadge.parse(Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])))
    }
}

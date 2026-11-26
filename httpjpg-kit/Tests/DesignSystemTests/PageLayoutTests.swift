import XCTest

@testable import DesignSystem

final class PageLayoutTests: XCTestCase {

    func testOneColumnIsTheCardWidth() {
        XCTAssertEqual(
            PageLayout.columnWidth(viewport: 393, columns: 1, spacing: 24),
            PageLayout.cardWidth(viewport: 393)
        )
    }

    func testColumnsShareTheInsetWidthMinusTheGaps() {
        // iPhone Duo unfolded in landscape: 951pt, gutters 2 × 16, two 24pt gaps.
        XCTAssertEqual(PageLayout.columnWidth(viewport: 951, columns: 3, spacing: 24), 290.333, accuracy: 0.001)
    }

    func testANonsenseColumnCountFallsBackToOne() {
        XCTAssertEqual(
            PageLayout.columnWidth(viewport: 768, columns: 0, spacing: 24),
            PageLayout.cardWidth(viewport: 768)
        )
    }

    func testANarrowViewportNeverGoesNegative() {
        XCTAssertEqual(PageLayout.columnWidth(viewport: 40, columns: 3, spacing: 24), 0)
    }
}

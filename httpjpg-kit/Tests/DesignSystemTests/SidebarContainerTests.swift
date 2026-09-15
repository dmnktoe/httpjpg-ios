import XCTest

@testable import DesignSystem

final class SidebarContainerTests: XCTestCase {
    func testClosedDrawerTracksAnOpeningDrag() {
        let geometry = SidebarDrawerGeometry(
            width: 320,
            isOpen: false,
            translation: 80
        )

        XCTAssertEqual(geometry.position, 80)
        XCTAssertEqual(geometry.progress, 0.25)
        XCTAssertEqual(geometry.pageScale, 0.9875)
    }

    func testDrawerDoesNotTravelPastTheClosedEdge() {
        let geometry = SidebarDrawerGeometry(
            width: 320,
            isOpen: false,
            translation: -80
        )

        XCTAssertEqual(geometry.position, 0)
        XCTAssertEqual(geometry.progress, 0)
    }

    func testDrawerDampsOpenEdgeOvershoot() {
        let geometry = SidebarDrawerGeometry(
            width: 320,
            isOpen: true,
            translation: 80
        )

        XCTAssertEqual(geometry.position, 340)
        XCTAssertEqual(geometry.progress, 1)
    }

    func testProjectedPositionChoosesTheNearestSide() {
        let opening = SidebarDrawerGeometry(width: 320, isOpen: false, translation: 80)
        let closing = SidebarDrawerGeometry(width: 320, isOpen: true, translation: -80)

        XCTAssertTrue(opening.settlesOpen(projectedTranslation: 200))
        XCTAssertFalse(closing.settlesOpen(projectedTranslation: -200))
    }

    func testChromeFollowsPageScaleAroundViewportCenter() {
        let geometry = SidebarDrawerGeometry(
            width: 320,
            isOpen: true,
            translation: 0
        )

        XCTAssertEqual(
            geometry.chromeVerticalOffset(viewportHeight: 800),
            -20,
            accuracy: 0.0001
        )
    }
}

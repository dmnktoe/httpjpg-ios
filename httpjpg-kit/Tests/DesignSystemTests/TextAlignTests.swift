import SwiftUI
import UIKit
import XCTest

@testable import DesignSystem

final class TextAlignTests: XCTestCase {
    func testCMSValuesMapOntoTheFourAlignmentsTheSiteShips() {
        XCTAssertEqual(TextAlign(cmsValue: "left"), .left)
        XCTAssertEqual(TextAlign(cmsValue: "center"), .center)
        XCTAssertEqual(TextAlign(cmsValue: "right"), .right)
        XCTAssertEqual(TextAlign(cmsValue: "justify"), .justify)
    }

    func testUnknownOrEmptyValuesFallBackToLeft() {
        XCTAssertEqual(TextAlign(cmsValue: nil), .left)
        XCTAssertEqual(TextAlign(cmsValue: ""), .left)
        XCTAssertEqual(TextAlign(cmsValue: "start"), .left, "the editor's start is not a CMS option")
    }

    func testRightAndCenterPinTheFrameSoShortLinesActuallyMove() {
        XCTAssertEqual(TextAlign.center.frame, .center)
        XCTAssertEqual(TextAlign.right.frame, .trailing)
        XCTAssertEqual(TextAlign.left.frame, .leading)
        XCTAssertEqual(TextAlign.justify.frame, .leading)
        XCTAssertEqual(TextAlign.right.multiline, .trailing)
        XCTAssertEqual(TextAlign.justify.nsAlignment, .justified)
        XCTAssertEqual(TextAlign.right.nsAlignment, .right)
        XCTAssertEqual(TextAlign.center.nsAlignment, .center)
        XCTAssertEqual(TextAlign.left.nsAlignment, .left)
    }
}

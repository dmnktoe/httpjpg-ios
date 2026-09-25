import SwiftUI
import Tokens
import XCTest

@testable import DesignSystem

final class JustifiedTextColorTests: XCTestCase {
    func testAJustifiedHeadlineKeepsTheColourItWasGiven() {
        let cms = Palette.named("neutral.300")

        XCTAssertNotNil(cms)
        XCTAssertEqual(
            Headline("we're yet to find out", alignment: .justify, color: cms).resolvedColor(for: .light),
            cms
        )
    }

    func testAJustifiedHeadlineFallsBackToThePageForeground() {
        XCTAssertEqual(
            Headline("we're yet to find out", alignment: .justify).resolvedColor(for: .dark),
            PageTheme.dark.foreground
        )
    }

    func testAJustifiedParagraphKeepsTheColourItWasGiven() {
        let cms = Palette.named("#92A0A0")

        XCTAssertNotNil(cms)
        XCTAssertEqual(
            BodyText("trap by", alignment: .justify, color: cms).resolvedColor(for: .light),
            cms
        )
    }

    func testAJustifiedParagraphFallsBackToThePageForeground() {
        XCTAssertEqual(
            BodyText("trap by", alignment: .justify).resolvedColor(for: .light),
            PageTheme.light.foreground
        )
    }
}

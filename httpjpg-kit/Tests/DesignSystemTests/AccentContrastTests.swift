import SwiftUI
import Tokens
import XCTest

/// `onNamed` used to understand only hex and the two keywords, so a ramp token
/// like `primary.700` resolved a colour but no glyph to put on it — the chrome
/// then fell back to black on a near-black fill.
final class AccentContrastTests: XCTestCase {
    func testHexAccentsStillResolve() {
        XCTAssertEqual(Palette.onNamed("#000000"), Palette.white)
        XCTAssertEqual(Palette.onNamed("#FFFFFF"), Palette.black)
        XCTAssertEqual(Palette.onNamed("#fff"), Palette.black)
    }

    func testKeywordAccentsStillResolve() {
        XCTAssertEqual(Palette.onNamed("black"), Palette.white)
        XCTAssertEqual(Palette.onNamed("white"), Palette.black)
    }

    func testRampTokensNowResolveAGlyphColour() {
        XCTAssertEqual(Palette.onNamed("primary.700"), Palette.white)
        XCTAssertEqual(Palette.onNamed("neutral.950"), Palette.white)
        XCTAssertEqual(Palette.onNamed("accent.300"), Palette.black)
        XCTAssertEqual(Palette.onNamed("warning.100"), Palette.black)
    }

    func testEveryRampTokenNamedResolvesAlsoResolvesAGlyph() {
        let ramps = ["neutral", "primary", "accent", "success", "warning", "danger"]
        let steps = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950]

        for ramp in ramps {
            for step in steps {
                let token = "\(ramp).\(step)"
                XCTAssertNotNil(Palette.named(token), "\(token) has no colour")
                XCTAssertNotNil(Palette.onNamed(token), "\(token) has no glyph colour")
            }
        }
    }

    func testUnknownTokensStayUnresolved() {
        XCTAssertNil(Palette.onNamed("chartreuse"))
        XCTAssertNil(Palette.onNamed("primary.42"))
        XCTAssertNil(Palette.onNamed(""))
        XCTAssertNil(Palette.onNamed(nil))
        XCTAssertNil(Palette.prefersLightForeground("chartreuse"))
    }

    func testTheNavigationBarAndItsButtonsAgreeOnContrast() {
        for token in ["#000000", "#FFFFFF", "primary.700", "accent.300", "black", "white"] {
            let prefersLight = Palette.prefersLightForeground(token)
            XCTAssertEqual(
                Palette.onNamed(token),
                prefersLight == true ? Palette.white : Palette.black,
                "\(token) disagrees between the title and the buttons"
            )
        }
    }
}

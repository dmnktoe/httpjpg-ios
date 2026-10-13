import SwiftUI
import Tokens
import XCTest

@testable import DesignSystem

final class PillTintTests: XCTestCase {

    func testAnUnselectedPillWearsClearSystemGlass() {
        let tint = PillTint.forSelection(false, theme: .light, accent: Palette.named("#FF0000"))

        XCTAssertEqual(tint, .idle(.light))
        XCTAssertNil(tint.fill, "idle pills match the untinted hamburger glass")
        XCTAssertNil(tint.stroke)
        XCTAssertEqual(tint.label, PageTheme.light.foreground)
    }

    func testTheAccentOnlyReachesTheSelectedPill() {
        let accent = Palette.named("#FF0000")

        let idle = PillTint.forSelection(false, theme: .light, accent: accent)
        let selected = PillTint.forSelection(true, theme: .light, accent: accent)

        XCTAssertNil(idle.fill)
        XCTAssertEqual(selected.fill, accent)
        XCTAssertFalse(selected.isOpaque, "opaque selection drops out of the glass container and shoves neighbours")
        XCTAssertNil(selected.stroke, "a stroke draws a second shape inside the glass")
    }

    func testAnAccentlessSelectionInvertsThePage() {
        let light = PillTint.selected(.light)
        let dark = PillTint.selected(.dark)

        XCTAssertEqual(light.label, PageTheme.light.background)
        XCTAssertEqual(dark.label, PageTheme.dark.background)
        XCTAssertEqual(light.fill, PageTheme.light.foreground)
        XCTAssertEqual(dark.fill, PageTheme.dark.foreground)
        XCTAssertFalse(light.isOpaque)
    }


    func testAControlFallsBackToChromeWithoutAnAccent() {
        let tint = PillTint.control(.dark)

        XCTAssertEqual(tint.fill, PageTheme.dark.chromeFill)
        XCTAssertEqual(tint.label, PageTheme.dark.foreground)
    }

    func testAControlTakesTheGlyphColourThePageResolved() {
        let tint = PillTint.control(.light, accent: Palette.named("#000000"), onAccent: Palette.onNamed("#000000"))

        XCTAssertEqual(tint.label, Palette.white)
    }

    func testAnAccentedControlFillsOutright() {
        let accent = Palette.named("#FF0000")
        let tint = PillTint.control(.light, accent: accent)

        XCTAssertTrue(tint.isOpaque)
        XCTAssertEqual(tint.fill, accent)
        XCTAssertNil(tint.stroke, "an outline draws a second, smaller shape inside the button")
    }

    func testAnUnaccentedControlStaysGlass() {
        XCTAssertFalse(PillTint.control(.light).isOpaque)
        XCTAssertFalse(PillTint.idle(.light).isOpaque)
    }

    func testAControlOverMediaIgnoresTheTheme() {
        XCTAssertEqual(PillTint.overMedia(), PillTint.overMedia())
        XCTAssertEqual(PillTint.overMedia().label, Palette.white)
        XCTAssertNotNil(PillTint.overMedia().fill)
    }
}

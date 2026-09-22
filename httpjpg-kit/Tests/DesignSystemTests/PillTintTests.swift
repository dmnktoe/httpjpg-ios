import SwiftUI
import Tokens
import XCTest

@testable import DesignSystem

final class PillTintTests: XCTestCase {
    // MARK: - Selection

    func testAnUnselectedPillWearsThePagesChrome() {
        let tint = PillTint.forSelection(false, theme: .light, accent: Palette.named("#FF0000"))

        XCTAssertEqual(tint, .idle(.light))
    }

    /// Tinting every pill in a row with the accent leaves nothing to mark the
    /// selection, so the accent only lands on the selected one.
    func testTheAccentOnlyReachesTheSelectedPill() {
        let accent = Palette.named("#FF0000")

        let idle = PillTint.forSelection(false, theme: .light, accent: accent)
        let selected = PillTint.forSelection(true, theme: .light, accent: accent)

        XCTAssertEqual(idle.fill, PageTheme.light.chromeFill)
        XCTAssertNotEqual(selected.fill, idle.fill)
        XCTAssertEqual(selected.stroke, accent)
    }

    func testAnAccentlessSelectionInvertsThePage() {
        let light = PillTint.selected(.light)
        let dark = PillTint.selected(.dark)

        XCTAssertEqual(light.label, PageTheme.light.background)
        XCTAssertEqual(dark.label, PageTheme.dark.background)
        XCTAssertNotEqual(light.fill, dark.fill)
    }

    // MARK: - Controls

    func testAControlFallsBackToChromeWithoutAnAccent() {
        let tint = PillTint.control(.dark)

        XCTAssertEqual(tint.fill, PageTheme.dark.chromeFill)
        XCTAssertEqual(tint.label, PageTheme.dark.foreground)
    }

    func testAControlTakesTheGlyphColourThePageResolved() {
        let tint = PillTint.control(.light, accent: Palette.named("#000000"), onAccent: Palette.onNamed("#000000"))

        XCTAssertEqual(tint.label, Palette.white)
    }

    /// `Glass.tint` stays sheer however saturated the colour, so an accented
    /// header button has to ask for the fill underneath or it reads as a hint of
    /// the accent rather than the accent.
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

    /// A control over a photo cannot borrow the page theme — the backdrop is the
    /// image, so it stays dark in both appearances.
    func testAControlOverMediaIgnoresTheTheme() {
        XCTAssertEqual(PillTint.overMedia(), PillTint.overMedia())
        XCTAssertEqual(PillTint.overMedia().label, Palette.white)
        XCTAssertNotEqual(PillTint.overMedia().fill, PageTheme.light.chromeFill)
    }
}

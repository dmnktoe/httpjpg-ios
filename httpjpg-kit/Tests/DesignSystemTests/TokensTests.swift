import SwiftUI
import UIKit
import XCTest

@testable import DesignSystem

final class TokensTests: XCTestCase {
    func testResolvesPandaColorKeys() {
        XCTAssertEqual(Palette.named("primary.500"), Palette.primary.s500)
        XCTAssertEqual(Palette.named("neutral.950"), Palette.neutral.s950)
        XCTAssertEqual(Palette.named("black"), Palette.black)
        XCTAssertEqual(Palette.named("white"), Palette.white)
    }

    func testRejectsUnknownColorKeys() {
        XCTAssertNil(Palette.named(nil))
        XCTAssertNil(Palette.named(""))
        XCTAssertNil(Palette.named("brand.500"))
        XCTAssertNil(Palette.named("primary.550"))
        XCTAssertNil(Palette.named("primary"))
    }

    func testSpacingScaleMatchesRemValues() {
        XCTAssertEqual(Spacing.step(4), 16)
        XCTAssertEqual(Spacing.step(12), 48)
        XCTAssertEqual(Spacing.named("8"), 32)
        XCTAssertNil(Spacing.named("13"), "13 is not a step on the Panda scale")
        XCTAssertNil(Spacing.named(nil))
    }

    func testClampMatchesCSSClamp() {
        let narrow = Typography.clamp(min: 36, slope: 0.05, intercept: 16, max: 60, width: 320)
        let wide = Typography.clamp(min: 36, slope: 0.05, intercept: 16, max: 60, width: 1400)
        let middle = Typography.clamp(min: 36, slope: 0.05, intercept: 16, max: 60, width: 600)

        XCTAssertEqual(narrow, 36, "below the lower bound the minimum wins")
        XCTAssertEqual(wide, 60, "above the upper bound the maximum wins")
        XCTAssertEqual(middle, 46, accuracy: 0.001)
    }

    func testHeadlineLevelsKeepTheirWebClamps() {
        XCTAssertEqual(Headline.Level.one.clamp.min, 36)
        XCTAssertEqual(Headline.Level.two.clamp.max, 48)
        XCTAssertEqual(Headline.Level.three.clamp.min, 24)
    }

    func testPageThemeFlipsSemanticColors() {
        XCTAssertEqual(PageTheme.light.background, Palette.white)
        XCTAssertEqual(PageTheme.light.foreground, Palette.black)
        XCTAssertEqual(PageTheme.dark.background, Palette.black)
        XCTAssertEqual(PageTheme.dark.foreground, Palette.white)
        XCTAssertEqual(PageTheme.light.border, Palette.neutral.s300)
        XCTAssertEqual(PageTheme.dark.border, Palette.neutral.s700)
        XCTAssertEqual(PageTheme.dark.colorScheme, .dark)
    }

    func testHeadlineResolvesToABundledCondensedFace() {
        let resolved = Typography.Family.headline
        XCTAssertNotNil(
            UIFont(name: resolved, size: 32),
            "\(resolved) did not instantiate — the font stack resolved to a name iOS cannot load"
        )
        XCTAssertNotEqual(
            resolved,
            "HelveticaNeue-CondensedBlack",
            "fell through to the system fallback; Anton-Regular.ttf is not reaching Bundle.module"
        )
    }

    func testEveryTokenFamilyResolvesToALoadableFace() {
        for (token, name) in FontRegistry.resolvedFamilies {
            XCTAssertNotNil(UIFont(name: name, size: 16), "\(token) resolved to unloadable \(name)")
        }
    }

    func testAsciiFurnitureIsUnchangedFromTheWeb() {
        XCTAssertEqual(Ascii.tape, "▰▰▰▱▱▱▰▰▰▱▱▱▰▰▰")
        XCTAssertEqual(Ascii.sparkles, "·°•. ⋆ ✦ ⋆ .•°·")
        XCTAssertEqual(Ascii.dividerDots, "· ─ · ─ · ─ · ─ ·")
    }
}

final class WorkCardDateTests: XCTestCase {
    private func date(_ iso: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        return try XCTUnwrap(formatter.date(from: iso))
    }

    func testPartsUseGermanFormattingAndMonthGlyphs() throws {
        let parts = WorkCardDate.parts(of: try date("2024-06-15T12:00:00Z"))
        XCTAssertEqual(parts.day, "15")
        XCTAssertEqual(parts.year, "24")
        XCTAssertEqual(parts.monthSymbol, "🌊", "June is the sixth glyph in MONTH_SYMBOLS")
    }

    func testJanuaryAndDecemberGlyphs() throws {
        XCTAssertEqual(WorkCardDate.parts(of: try date("2024-01-10T12:00:00Z")).monthSymbol, "❄")
        XCTAssertEqual(WorkCardDate.parts(of: try date("2024-12-10T12:00:00Z")).monthSymbol, "✨")
    }

    func testFullYear() throws {
        XCTAssertEqual(WorkCardDate.year(of: try date("2024-06-15T12:00:00Z")), "2024")
    }

    func testMidnightKeepsItsAuthoredDayAndYear() throws {
        let newYear = try date("2024-01-01T00:00:00Z")
        XCTAssertEqual(WorkCardDate.parts(of: newYear).day, "01")
        XCTAssertEqual(WorkCardDate.parts(of: newYear).monthSymbol, "❄")
        XCTAssertEqual(WorkCardDate.year(of: newYear), "2024")
    }
}

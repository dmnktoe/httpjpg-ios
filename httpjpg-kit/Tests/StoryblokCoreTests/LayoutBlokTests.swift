import Tokens
import XCTest

@testable import StoryblokCore

final class LayoutBlokTests: XCTestCase {
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try ContentClient.decoder().decode(T.self, from: Data(json.utf8))
    }

    func testBlokSpacingResolvesMdThenLgCascade() throws {
        let spacing = try decode(BlokSpacing.self, """
        {"mt":"4","mtMd":"8","mtLg":"12","mb":"2"}
        """)
        XCTAssertEqual(spacing.resolved(viewportWidth: 400).marginTop, 16)
        XCTAssertEqual(spacing.resolved(viewportWidth: 800).marginTop, 32)
        XCTAssertEqual(spacing.resolved(viewportWidth: 1100).marginTop, 48)
        XCTAssertEqual(spacing.resolved(viewportWidth: 1100).marginBottom, 8)
        XCTAssertEqual(spacing.resolved(viewportWidth: 800).marginTop, spacing.resolved(viewportWidth: 900).marginTop)
    }

    func testGridDecodesResponsiveColumns() throws {
        let blok = try decode(GridBlok.self, """
        {"_uid":"g1","component":"grid","items":[],"columns":"2","columnsMd":"3","columnsLg":"auto","gap":"4"}
        """)
        XCTAssertEqual(blok.columns, "2")
        XCTAssertEqual(blok.columnsMd, "3")
        XCTAssertEqual(blok.columnsLg, "auto")
        XCTAssertEqual(blok.columnCount(viewportWidth: 400, layoutWidth: 400), 2)
        XCTAssertEqual(blok.columnCount(viewportWidth: 800, layoutWidth: 800), 3)
        XCTAssertEqual(blok.columnCount(viewportWidth: 1200, layoutWidth: 1200), 6)
    }

    func testGridItemDecodesSpanAndVisibility() throws {
        let blok = try decode(GridItemBlok.self, """
        {"_uid":"gi1","component":"grid_item","content":[],"colSpan":"2","colSpanMd":"full",
         "hiddenBase":true,"hiddenMd":false}
        """)
        XCTAssertEqual(blok.colSpan, "2")
        XCTAssertEqual(blok.colSpanMd, "full")
        XCTAssertTrue(blok.isHidden(viewportWidth: 390))
        XCTAssertFalse(blok.isHidden(viewportWidth: 800))
        XCTAssertEqual(blok.resolvedColumnSpan(viewportWidth: 390), .columns(2))
        XCTAssertEqual(blok.resolvedColumnSpan(viewportWidth: 800), .full)
    }

    func testSectionDecodesContainerFields() throws {
        let blok = try decode(SectionBlok.self, """
        {"_uid":"s1","component":"section","content":[],"useContainer":true,
         "containerSize":"lg","containerAlign":"left"}
        """)
        XCTAssertTrue(blok.usesContainer)
        XCTAssertEqual(blok.containerSize, "lg")
        XCTAssertEqual(blok.containerAlign, "left")
        XCTAssertEqual(BlokContainerSize.maxWidthPoints(for: blok.containerSize), 1024)
    }

    func testContainerDecodesWidthAndCenter() throws {
        let blok = try decode(ContainerBlok.self, """
        {"_uid":"c1","component":"container","body":[],"width":"xl","center":"false"}
        """)
        XCTAssertEqual(blok.width, "xl")
        XCTAssertFalse(blok.isCentered)
        XCTAssertEqual(BlokContainerSize.maxWidthPoints(for: blok.width), 1280)
    }

    func testRichTextDecodesMaxWidth() throws {
        let blok = try decode(RichTextBlok.self, """
        {"_uid":"r1","component":"richtext","content":{"type":"doc","content":[]},"maxWidth":"45ch"}
        """)
        XCTAssertEqual(blok.maxWidth, "45ch")
        let points = BlokProseMaxWidth.maxWidthPoints(for: blok.maxWidth)
        XCTAssertEqual(points ?? 0, 45 * BlokProseMaxWidth.characterWidth, accuracy: 0.01)
    }

    func testRichTextDefaultMaxWidthMatches65ch() throws {
        let blok = try decode(RichTextBlok.self, """
        {"_uid":"r2","component":"richtext","content":{"type":"doc","content":[]}}
        """)
        XCTAssertNil(blok.maxWidth)
        XCTAssertEqual(
            BlokProseMaxWidth.maxWidthPoints(for: blok.maxWidth) ?? 0,
            65 * BlokProseMaxWidth.characterWidth,
            accuracy: 0.01
        )
        XCTAssertNil(BlokProseMaxWidth.maxWidthPoints(for: "none"))
    }
}

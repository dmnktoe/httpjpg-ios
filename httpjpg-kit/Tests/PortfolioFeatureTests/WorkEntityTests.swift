import StoryblokCore
import XCTest

@testable import PortfolioFeature

final class WorkEntityTests: XCTestCase {
    private let date = Date(timeIntervalSince1970: 1_700_000_000)

    func testCarriesTheTagsAndDateSpotlightSearchesOn() {
        let entity = WorkEntity(item: item())

        XCTAssertEqual(entity.id, "nachtbus")
        XCTAssertEqual(entity.keywords, ["Motion", "Print"])
        XCTAssertEqual(entity.date, date)
    }

    func testTheAttributeSetGoesBeyondTheDisplayRepresentation() throws {
        guard #available(iOS 18.0, *) else { throw XCTSkip("IndexedEntity landed in iOS 18") }
        let attributes = WorkEntity(item: item()).attributeSet

        XCTAssertEqual(attributes.title, "NACHTBUS")
        XCTAssertEqual(attributes.contentDescription, "A night bus.")
        XCTAssertEqual(attributes.keywords, ["Motion", "Print"])
        XCTAssertEqual(attributes.contentModificationDate, date)
    }

    func testAClearedSummaryLeavesNoEmptyDescriptionBehind() throws {
        guard #available(iOS 18.0, *) else { throw XCTSkip("IndexedEntity landed in iOS 18") }
        let attributes = WorkEntity(item: item(summary: "")).attributeSet

        XCTAssertNil(attributes.contentDescription)
        XCTAssertNil(WorkEntity(id: "x", title: "X").attributeSet.keywords)
    }

    private func item(summary: String = "A night bus.") -> WorkItem {
        WorkItem(
            id: "nachtbus",
            slug: "nachtbus",
            fullSlug: "work/nachtbus",
            title: "NACHTBUS",
            summary: summary,
            thumbnailURL: nil,
            imageFilenames: [],
            isDraft: false,
            isExternal: false,
            externalURL: nil,
            date: date,
            tags: ["Motion", "Print"]
        )
    }
}

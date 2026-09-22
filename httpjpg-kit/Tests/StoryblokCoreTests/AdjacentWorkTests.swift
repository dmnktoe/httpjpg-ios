import StoryblokCore
import XCTest

final class AdjacentWorkTests: XCTestCase {
    private let items: [WorkItem] = [
        WorkItem(
            id: "a",
            slug: "alpha",
            fullSlug: "work/alpha",
            title: "Alpha",
            thumbnailURL: nil,
            imageFilenames: [],
            isDraft: false,
            isExternal: false,
            externalURL: nil,
            date: Date(timeIntervalSince1970: 1_700_000_000)
        ),
        WorkItem(
            id: "b",
            slug: "beta",
            fullSlug: "work/beta",
            title: "Beta",
            thumbnailURL: nil,
            imageFilenames: [],
            isDraft: false,
            isExternal: false,
            externalURL: nil,
            date: Date(timeIntervalSince1970: 1_600_000_000)
        ),
        WorkItem(
            id: "c",
            slug: "gamma",
            fullSlug: "work/gamma",
            title: "Gamma",
            thumbnailURL: nil,
            imageFilenames: [],
            isDraft: false,
            isExternal: false,
            externalURL: nil,
            date: Date(timeIntervalSince1970: 1_500_000_000)
        ),
    ]

    func testFindsPrevAndNextByDateOrder() {
        let adjacent = AdjacentWork.neighbours(for: "beta", in: items)
        XCTAssertEqual(adjacent.prev?.slug, "alpha")
        XCTAssertEqual(adjacent.next?.slug, "gamma")
    }

    func testFirstItemHasNoPreviousNeighbour() {
        let adjacent = AdjacentWork.neighbours(for: "alpha", in: items)
        XCTAssertNil(adjacent.prev)
        XCTAssertEqual(adjacent.next?.slug, "beta")
    }

    func testUnknownSlugReturnsEmptyNeighbours() {
        let adjacent = AdjacentWork.neighbours(for: "missing", in: items)
        XCTAssertNil(adjacent.prev)
        XCTAssertNil(adjacent.next)
    }
}

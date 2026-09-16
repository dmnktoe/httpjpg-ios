import StoryblokCore
import XCTest

@testable import PortfolioFeature

final class SidebarSearchTests: XCTestCase {
    private let atlas = SidebarSearchTests.makeItem(title: "ATLAS")
    private let strada = SidebarSearchTests.makeItem(
        title: "Strada",
        date: Date(timeIntervalSince1970: 1_000_000_000)
    )

    func testAnEmptyQueryKeepsEveryProject() {
        let items = [atlas, strada]

        XCTAssertEqual(SidebarSearch.filter(items, matching: "").map(\.slug), items.map(\.slug))
    }

    func testAWhitespaceQueryCountsAsEmpty() {
        let items = [atlas, strada]

        XCTAssertEqual(SidebarSearch.filter(items, matching: "   ").map(\.slug), items.map(\.slug))
    }

    func testTheMatchIgnoresCase() {
        XCTAssertEqual(SidebarSearch.filter([atlas, strada], matching: "atl").map(\.slug), ["atlas"])
        XCTAssertEqual(SidebarSearch.filter([atlas, strada], matching: "STRA").map(\.slug), ["strada"])
    }

    func testSurroundingWhitespaceIsTrimmedOffTheQuery() {
        XCTAssertEqual(SidebarSearch.filter([atlas, strada], matching: "  atlas ").map(\.slug), ["atlas"])
    }

    func testAQueryNothingCarriesEmptiesTheList() {
        XCTAssertTrue(SidebarSearch.filter([atlas, strada], matching: "zzz").isEmpty)
    }

    func testTheYearGroupsRunOnTheMatchesOnly() {
        let groups = SidebarSearch.groups(from: [atlas, strada], matching: "strada")

        XCTAssertEqual(groups.map(\.year), ["2001"])
        XCTAssertEqual(groups.first?.items.map(\.slug), ["strada"])
    }

    func testUndatedMatchesStillGroup() {
        let groups = SidebarSearch.groups(from: [atlas, strada], matching: "atlas")

        XCTAssertEqual(groups.map(\.year), [WorkYearGroup.undatedYear])
    }

    private static func makeItem(title: String, date: Date? = nil) -> WorkItem {
        let slug = title.lowercased()
        return WorkItem(
            id: slug,
            slug: slug,
            fullSlug: "work/" + slug,
            title: title,
            thumbnailURL: nil,
            imageFilenames: [],
            isDraft: false,
            isExternal: false,
            externalURL: nil,
            date: date,
            tags: []
        )
    }
}

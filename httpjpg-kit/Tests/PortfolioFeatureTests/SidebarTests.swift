import StoryblokCore
import XCTest

@testable import PortfolioFeature

@MainActor
final class SidebarTests: XCTestCase {
    private func makeApp() -> AppModel {
        AppModel(configuration: StoryblokConfiguration(accessToken: "mock", source: .mock))
    }

    func testOpeningAProjectFromTheSidebarRoutesAndClosesIt() async throws {
        let app = makeApp()
        await app.workIndex.load()
        app.isSidebarOpen = true

        let project = try XCTUnwrap(app.workIndex.allWork.first)
        app.open(work: project)

        XCTAssertFalse(app.isSidebarOpen)
        XCTAssertEqual(app.selectedTab, .work)
        XCTAssertEqual(app.workPath.map(\.slug), [project.slug])
    }

    func testTheSidebarListIgnoresTheIndexFilters() async {
        let app = makeApp()
        await app.workIndex.load()

        app.workIndex.select(variant: .websites)
        app.workIndex.toggle(tag: "a-tag-nothing-carries")

        XCTAssertTrue(app.workIndex.visibleItems.isEmpty)
        XCTAssertFalse(app.workIndex.allWork.isEmpty)
    }

    func testTheSidebarListSpansBothVariants() async throws {
        let app = makeApp()
        await app.workIndex.load()

        let collection = try await app.client.workIndex()
        let slugs = Set(app.workIndex.allWork.map(\.slug))

        XCTAssertFalse(collection.websites.isEmpty)
        for item in collection.projects + collection.websites {
            XCTAssertTrue(slugs.contains(item.slug), "\(item.slug) missing from the drawer")
        }
        XCTAssertEqual(app.workIndex.allWork.count, slugs.count)
    }

    func testTheSidebarListRunsNewestFirstAcrossVariants() async {
        let app = makeApp()
        await app.workIndex.load()

        let dates = app.workIndex.allWork.map { $0.date ?? .distantPast }
        XCTAssertEqual(dates, dates.sorted(by: >))
    }

    func testTheSidebarGroupsWorkByDescendingYear() async {
        let app = makeApp()
        await app.workIndex.load()

        let groups = app.workIndex.workByYear
        let years = groups.map(\.year)
        // The undated placeholder sorts ahead of digits, so only the dated years get the order check.
        let dated = years.filter { $0 != WorkYearGroup.undatedYear }

        XCTAssertEqual(dated, dated.sorted(by: >))
        XCTAssertEqual(years.count, Set(years).count)
        XCTAssertEqual(groups.flatMap(\.items), app.workIndex.allWork)
        if years.contains(WorkYearGroup.undatedYear) {
            XCTAssertEqual(years.last, WorkYearGroup.undatedYear)
        }
    }

    func testUndatedWorkTrailsTheDatedYears() {
        // Mid-year so the year label holds whatever timezone the simulator runs in.
        let dated = makeItem(slug: "dated", date: Date(timeIntervalSince1970: 1_000_000_000))
        let undated = makeItem(slug: "undated", date: nil)

        let groups = WorkYearGroup.groups(from: [undated, dated])

        XCTAssertEqual(groups.map(\.year), ["2001", WorkYearGroup.undatedYear])
        XCTAssertEqual(groups.last?.items.map(\.slug), ["undated"])
        XCTAssertEqual(groups.last?.accessibilityLabel, "undated")
    }

    private func makeItem(slug: String, date: Date?) -> WorkItem {
        WorkItem(
            id: slug,
            slug: slug,
            fullSlug: "work/" + slug,
            title: slug,
            thumbnailURL: nil,
            imageFilenames: [],
            isDraft: false,
            isExternal: false,
            externalURL: nil,
            date: date,
            tags: []
        )
    }

    func testToggleSidebarFlipsTheDrawer() {
        let app = makeApp()
        XCTAssertFalse(app.isSidebarOpen)

        app.toggleSidebar()
        XCTAssertTrue(app.isSidebarOpen)

        app.toggleSidebar()
        XCTAssertFalse(app.isSidebarOpen)
    }

    func testTheDrawerSwipeStandsDownInsideANavigationStack() {
        let app = makeApp()
        XCTAssertTrue(app.isAtNavigationRoot)

        app.workPath = [WorkRoute(slug: "atlas", title: "ATLAS")]
        XCTAssertFalse(app.isAtNavigationRoot)

        app.selectedTab = .info
        XCTAssertTrue(app.isAtNavigationRoot)
    }
}

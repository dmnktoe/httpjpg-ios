import StoryblokContent
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

    func testTheDrawerSwipeStandsDownInsideANavigationStack() {
        let app = makeApp()
        XCTAssertTrue(app.isAtNavigationRoot)

        app.workPath = [WorkRoute(slug: "atlas", title: "ATLAS")]
        XCTAssertFalse(app.isAtNavigationRoot)

        app.selectedTab = .info
        XCTAssertTrue(app.isAtNavigationRoot)
    }
}

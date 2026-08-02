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

        let project = try XCTUnwrap(app.workIndex.allProjects.first)
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
        XCTAssertFalse(app.workIndex.allProjects.isEmpty)
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

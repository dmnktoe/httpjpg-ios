import StoryblokCore
import XCTest

@testable import PortfolioFeature

@MainActor
final class TabBarStateTests: XCTestCase {
    private func makeApp() -> AppModel {
        AppModel(configuration: StoryblokConfiguration(accessToken: "test-token"))
    }

    // MARK: - Visited tabs (keep-alive mounting)

    func testTheInitialTabCountsAsVisited() {
        XCTAssertEqual(makeApp().visitedTabs, [.work])
    }

    func testSelectingATabRecordsTheVisit() {
        let app = makeApp()

        app.select(tab: .info)

        XCTAssertEqual(app.visitedTabs, [.work, .info])
    }

    func testDirectTabWritesRecordTheVisitToo() {
        let app = makeApp()

        app.selectedTab = .info

        XCTAssertTrue(app.visitedTabs.contains(.info))
    }

    func testReselectingTheCurrentTabStillPopsItsPathToRoot() {
        let app = makeApp()
        app.perform(.work(slug: "atlas", title: "ATLAS"))

        app.select(tab: .work)

        XCTAssertTrue(app.workPath.isEmpty)
        XCTAssertEqual(app.scrollToTopTick(for: .work), 0)
    }

    func testReselectingAtTheRootScrollsToTopInsteadOfPopping() {
        let app = makeApp()

        app.select(tab: .work)
        app.select(tab: .work)

        XCTAssertEqual(app.scrollToTopTick(for: .work), 2)
        XCTAssertEqual(app.scrollToTopTick(for: .info), 0)
    }

}

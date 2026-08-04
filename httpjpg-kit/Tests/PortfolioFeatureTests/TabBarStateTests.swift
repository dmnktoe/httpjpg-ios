import StoryblokContent
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
    }

    // MARK: - Preview pill URL (derived, not set/cleared imperatively)

    func testThePreviewURLFollowsTheTopOfTheWorkPath() throws {
        let app = makeApp()
        let url = try XCTUnwrap(URL(string: "https://example.com"))
        app.perform(.work(slug: "atlas", title: "ATLAS"))

        app.registerPreviewURL(url, for: "atlas")

        XCTAssertEqual(app.previewURL, url)
    }

    func testThePreviewURLStaysAcrossTabSwitchesLikeTheMiniPlayer() throws {
        let app = makeApp()
        let url = try XCTUnwrap(URL(string: "https://example.com"))
        app.perform(.work(slug: "atlas", title: "ATLAS"))
        app.registerPreviewURL(url, for: "atlas")

        app.select(tab: .info)

        XCTAssertEqual(app.previewURL, url)
    }

    func testThePreviewURLHidesWhenTheDetailPopsAndReturnsWhenItComesBack() throws {
        let app = makeApp()
        let url = try XCTUnwrap(URL(string: "https://example.com"))
        app.perform(.work(slug: "atlas", title: "ATLAS"))
        app.registerPreviewURL(url, for: "atlas")

        app.workPath.removeAll()
        XCTAssertNil(app.previewURL)

        app.perform(.work(slug: "atlas", title: "ATLAS"))
        XCTAssertEqual(app.previewURL, url)
    }

    func testAWorkWithoutAnExternalLinkShowsNoPreview() {
        let app = makeApp()
        app.perform(.work(slug: "atlas", title: "ATLAS"))

        app.registerPreviewURL(nil, for: "atlas")

        XCTAssertNil(app.previewURL)
    }
}

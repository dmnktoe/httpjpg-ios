import StoryblokCore
import WidgetFeature
import XCTest

@testable import PortfolioFeature

@MainActor
final class QuickActionRoutingTests: XCTestCase {
    private func makeApp() -> AppModel {
        AppModel(configuration: StoryblokConfiguration(accessToken: "test-token"))
    }

    func testAWorkActionOpensItsDetailRoute() {
        let app = makeApp()
        app.selectedTab = .info

        app.perform(.work(slug: "atlas", title: "ATLAS"))

        XCTAssertEqual(app.selectedTab, .work)
        XCTAssertEqual(app.workPath, [WorkRoute(slug: "atlas", title: "ATLAS")])
    }

    func testASecondActionReplacesTheStackInsteadOfDeepeningIt() {
        let app = makeApp()

        app.perform(.work(slug: "one", title: "ONE"))
        app.perform(.work(slug: "two", title: "TWO"))

        XCTAssertEqual(app.workPath.map(\.slug), ["two"])
    }

    func testRepeatingTheSameWorkActionStillBumpsTheRouteToken() {
        let app = makeApp()

        app.perform(.work(slug: "atlas", title: "ATLAS"))
        let token = app.workRouteToken

        app.perform(.work(slug: "atlas", title: "ATLAS"))

        XCTAssertEqual(app.workPath.map(\.slug), ["atlas"])
        XCTAssertGreaterThan(app.workRouteToken, token)
    }

    func testAShuffleLandsSomewhereInsideItsPool() {
        let app = makeApp()
        let pool = ["one", "two", "three"]

        app.perform(.shuffle(pool: pool))

        XCTAssertEqual(app.workPath.count, 1)
        XCTAssertTrue(pool.contains(app.workPath[0].slug))
    }

    func testAShuffleDoesNotKeepPickingTheSameWork() {
        let app = makeApp()
        let pool = (1...10).map { "work-\($0)" }

        var picked = Set<String>()
        for _ in 0..<50 {
            app.perform(.shuffle(pool: pool))
            picked.formUnion(app.workPath.map(\.slug))
        }

        XCTAssertGreaterThan(picked.count, 1)
    }

    func testAnEmptyShuffleLeavesTheAppWhereItIs() {
        let app = makeApp()
        app.selectedTab = .info

        app.perform(.shuffle(pool: []))

        XCTAssertEqual(app.selectedTab, .info)
        XCTAssertTrue(app.workPath.isEmpty)
    }

    func testWidgetDeepLinksStillOpenTheirDetailRoute() throws {
        let app = makeApp()
        app.selectedTab = .info

        app.open(try XCTUnwrap(WidgetDeepLink.work(slug: "atlas")))

        XCTAssertEqual(app.selectedTab, .work)
        XCTAssertEqual(app.workPath.map(\.slug), ["atlas"])
    }

    func testAPageLinkOpensItInsideTheInfoTab() throws {
        let app = makeApp()

        app.open(try XCTUnwrap(WidgetDeepLink.page(slug: "feed-xml_html")))

        XCTAssertEqual(app.selectedTab, .info)
        XCTAssertEqual(app.infoPath.map(\.slug), ["feed-xml_html"])
    }

    func testTheInfoLinkLandsOnTheTabRoot() throws {
        let app = makeApp()
        app.open(try XCTUnwrap(WidgetDeepLink.page(slug: "feed-xml_html")))

        app.open(try XCTUnwrap(WidgetDeepLink.info))

        XCTAssertEqual(app.selectedTab, .info)
        XCTAssertTrue(app.infoPath.isEmpty)
    }

    func testTheWorkIndexLinkPopsBackToTheList() throws {
        let app = makeApp()
        app.perform(.work(slug: "atlas", title: "ATLAS"))

        app.open(try XCTUnwrap(WidgetDeepLink.workIndex))

        XCTAssertEqual(app.selectedTab, .work)
        XCTAssertTrue(app.workPath.isEmpty)
    }

    func testUnknownURLsAreIgnored() {
        let app = makeApp()

        app.open(URL(string: "httpjpg://info/imprint")!)

        XCTAssertTrue(app.workPath.isEmpty)
    }
}

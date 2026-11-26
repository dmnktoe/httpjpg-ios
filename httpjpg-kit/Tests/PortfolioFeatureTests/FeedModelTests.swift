import StoryblokCore
import XCTest

@testable import PortfolioFeature

@MainActor
final class FeedModelTests: XCTestCase {
    private func makeModel() -> FeedModel {
        FeedModel(
            client: ContentClient(
                configuration: StoryblokConfiguration(accessToken: "mock", source: .mock)
            )
        )
    }

    func testLoadingFetchesTheFirstPage() async {
        let model = makeModel()
        XCTAssertEqual(model.state, .idle)

        await model.load()

        XCTAssertEqual(model.state, .loaded)
        XCTAssertEqual(model.posts.count, 4)
        XCTAssertFalse(model.hasMore)
    }

    func testAPostIsChangedAndDroppedInPlace() async throws {
        let model = makeModel()
        await model.load()
        let first = try XCTUnwrap(model.posts.first)

        model.replace(first.with(blok: first.blok.with(caption: "edited")))
        XCTAssertEqual(model.posts.first?.blok.caption, "edited")
        XCTAssertEqual(model.posts.count, 4)

        model.remove(id: first.id)
        XCTAssertEqual(model.posts.count, 3)
        XCTAssertFalse(model.posts.contains { $0.id == first.id })

        model.replace(first)
        XCTAssertEqual(model.posts.count, 3)
    }

    func testTheCountSaysWhenMorePostsWait() async {
        let model = makeModel()
        await model.load()

        XCTAssertEqual(model.postCountLabel, "4")
    }

    func testTheTickerTakesEachCaptionsFirstLineAndShortensLongOnes() throws {
        func post(_ id: String, caption: String?) throws -> FeedPost {
            var json: [String: Any] = ["_uid": id, "component": "post"]
            json["caption"] = caption
            let blok = try JSONDecoder().decode(PostBlok.self, from: JSONSerialization.data(withJSONObject: json))
            return FeedPost(id: id, slug: id, fullSlug: "feed/\(id)", blok: blok)
        }
        let long = String(repeating: "a", count: 70)

        let lines = FeedModel.tickerLines(from: [
            try post("1", caption: "harbour\nsecond line"),
            try post("2", caption: nil),
            try post("3", caption: "   "),
            try post("4", caption: long),
        ])

        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(lines.first, "harbour")
        XCTAssertEqual(lines.last, String(repeating: "a", count: FeedModel.tickerLineLength - 1) + "…")
    }

    func testALoadedFeedIsNotFetchedAgainUnlessForced() async {
        let model = makeModel()
        await model.load()
        let ids = model.posts.map(\.id)

        await model.load()
        await model.load(force: true)

        XCTAssertEqual(model.posts.map(\.id), ids)
    }

    func testAppendingSkipsPostsAlreadyShown() async throws {
        let model = makeModel()
        await model.load()
        let posts = model.posts

        let merged = FeedModel.appending(Array(posts.suffix(2)), to: Array(posts.prefix(3)))

        XCTAssertEqual(merged.map(\.id), posts.map(\.id))
    }

    func testTheFeedTabIsARootAndReselectingItScrollsToTheTop() {
        let app = AppModel(configuration: StoryblokConfiguration(accessToken: "test-token"))

        app.select(tab: .feed)
        XCTAssertEqual(app.selectedTab, .feed)
        XCTAssertTrue(app.isAtNavigationRoot)
        XCTAssertEqual(app.scrollToTopTick(for: .feed), 0)

        app.select(tab: .feed)
        XCTAssertEqual(app.scrollToTopTick(for: .feed), 1)
    }

    func testReselectingTheFeedTabFromAPostReturnsToTheFeed() {
        let app = AppModel(configuration: StoryblokConfiguration(accessToken: "test-token"))
        app.select(tab: .feed)
        app.feedPath = [FeedRoute(id: "post-1")]
        XCTAssertFalse(app.isAtNavigationRoot)

        app.select(tab: .feed)

        XCTAssertTrue(app.feedPath.isEmpty)
        XCTAssertEqual(app.scrollToTopTick(for: .feed), 0)
    }
}

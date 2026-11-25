import XCTest

@testable import StoryblokCore

final class PostBlokTests: XCTestCase {
    private let client = ContentClient(
        configuration: StoryblokConfiguration(accessToken: "mock", source: .mock)
    )

    private let asset = "https://a.storyblok.com/f/281211/2592x1944/abcdef123456/dsc0001.jpg"

    func testACarouselDecodesWithItsFormatAndFits() throws {
        let post = try decode(
            """
            {"_uid": "p1", "component": "post", "caption": "  harbour  ", "date": "2026-11-25 10:00",
             "format": "4/5",
             "images": [
               {"_uid": "i1", "component": "post_image", "alt": "Harbour", "image": {"filename": "\(asset)"}},
               {"_uid": "i2", "component": "post_image", "fit": "contain", "image": {"filename": "\(asset)"}}
             ],
             "music": []}
            """
        )

        XCTAssertEqual(post.id, "p1")
        XCTAssertEqual(post.caption, "harbour")
        XCTAssertEqual(post.dateLabel, "2026-11-25")
        XCTAssertEqual(post.format, .portrait)
        XCTAssertEqual(post.aspectRatio, 0.8, accuracy: 0.0001)
        XCTAssertEqual(post.images.map(\.fit), [.cover, .contain])
        XCTAssertEqual(post.images.first?.accessibilityText, "Harbour")
        XCTAssertNil(post.music)
        XCTAssertFalse(post.isEmpty)
    }

    func testMissingFieldsFallBackToASquareFilledPost() throws {
        let post = try decode(
            """
            {"component": "post", "format": "16/9",
             "images": [{"component": "post_image", "fit": "stretch", "image": {"filename": "\(asset)"}}]}
            """
        )

        XCTAssertEqual(post.format, .square)
        XCTAssertEqual(post.aspectRatio, 1)
        XCTAssertEqual(post.images.first?.fit, .cover)
        XCTAssertNil(post.caption)
        XCTAssertNil(post.dateLabel)
    }

    func testAnOriginalPostTakesItsFirstImagesShape() throws {
        let post = try decode(
            """
            {"component": "post", "format": "original",
             "images": [{"component": "post_image", "image": {"filename": "\(asset)"}}]}
            """
        )

        XCTAssertEqual(post.aspectRatio, 2592.0 / 1944.0, accuracy: 0.0001)
    }

    func testImagesWithoutAFileAndVideosAreDropped() throws {
        let post = try decode(
            """
            {"component": "post",
             "images": [
               {"component": "post_image", "image": {"filename": ""}},
               {"component": "post_image", "image": {"filename": "https://a.storyblok.com/f/1/abc/clip.mp4"}},
               {"component": "post_image"}
             ]}
            """
        )

        XCTAssertTrue(post.images.isEmpty)
        XCTAssertTrue(post.isEmpty)
    }

    func testAMusicPostCarriesItsTrack() throws {
        let post = try decode(
            """
            {"component": "post", "caption": "new mix", "images": [],
             "music": [{"component": "music_player", "source": "mp3",
                        "src": "https://a.storyblok.com/f/1/abc/mix.mp3", "title": "mix"}]}
            """
        )

        XCTAssertEqual(post.music?.track?.title, "mix")
        XCTAssertFalse(post.isEmpty)
    }

    func testAnUnreadableDateHasNoLabel() throws {
        let post = try decode(#"{"component": "post", "date": "soon, maybe"}"#)

        XCTAssertNil(post.dateLabel)
    }

    func testTheFeedComesFromTheFixturesNewestFirst() async throws {
        let posts = try await client.feedPosts()

        XCTAssertEqual(posts.count, 4)
        XCTAssertEqual(posts.first?.fullSlug, "feed/20260712-181500-a1f3")
        XCTAssertEqual(posts.first?.blok.images.count, 3)
        XCTAssertEqual(posts.first?.blok.format, .portrait)
        XCTAssertEqual(posts[1].blok.images.first?.fit, .contain)
        XCTAssertNotNil(posts[2].blok.music?.track)
    }

    func testAPageBeyondTheLastIsEmpty() async throws {
        let posts = try await client.feedPosts(page: 2)

        XCTAssertTrue(posts.isEmpty)
    }

    func testPostsStayOutOfThePageIndex() {
        XCTAssertTrue(StorySlug.isHiddenFromPageIndex("20260712-181500-a1f3", component: "post"))
    }

    func testThePoolYieldsEveryImageThenTheTrack() async throws {
        let posts = try await client.feedPosts()
        let items = FeedPool.items(in: posts)

        let images = items.filter { if case .image = $0.kind { return true }; return false }
        let tracks = items.filter { if case .music = $0.kind { return true }; return false }
        XCTAssertEqual(images.count, 5)
        XCTAssertEqual(tracks.count, 1)
        XCTAssertEqual(Set(items.map(\.id)).count, items.count)
    }

    func testTheSharedPoolPutsPostsBeforeTheOldFeedPage() async throws {
        let posts = try await client.feedPosts()
        let pool = await client.feedPool()

        XCTAssertEqual(pool.first?.id, FeedPool.items(in: posts).first?.id)
        XCTAssertTrue(pool.contains { if case .video = $0.kind { return true }; return false })
    }

    private func decode(_ json: String) throws -> PostBlok {
        try JSONDecoder().decode(PostBlok.self, from: Data(json.utf8))
    }
}

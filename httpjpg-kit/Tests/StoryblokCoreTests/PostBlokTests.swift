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

    func testImagesWithoutAFileAreDroppedAndVideosKept() throws {
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

        XCTAssertEqual(post.images.count, 1)
        XCTAssertNotNil(post.images.first?.videoURL)
        XCTAssertFalse(post.isEmpty)
    }

    func testAnOriginalPostTakesItsShapeFromAVideoToo() throws {
        let post = try decode(
            """
            {"component": "post", "format": "original",
             "images": [{"component": "post_image", "image": {"filename": "https://a.storyblok.com/f/1/1080x1920/abc/clip.mp4"}}]}
            """
        )

        XCTAssertEqual(post.aspectRatio, 1080.0 / 1920.0, accuracy: 0.0001)
    }

    func testANewCaptionKeepsEverythingElse() throws {
        let post = try decode(
            """
            {"_uid": "p1", "component": "post", "caption": "old", "date": "2026-11-25 10:00", "format": "4/5",
             "images": [{"_uid": "i1", "component": "post_image", "image": {"filename": "\(asset)"}}]}
            """
        )

        let renamed = post.with(caption: "  new words  ")
        let cleared = post.with(caption: "   ")

        XCTAssertEqual(renamed.caption, "new words")
        XCTAssertNil(cleared.caption)
        XCTAssertEqual(renamed.id, "p1")
        XCTAssertEqual(renamed.date, "2026-11-25 10:00")
        XCTAssertEqual(renamed.format, .portrait)
        XCTAssertEqual(renamed.images.map(\.id), ["i1"])
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

    func testARecentPostTellsItsAgeAndAnOlderOneItsDate() throws {
        let post = try decode(#"{"component": "post", "date": "2026-11-25 10:00"}"#)
        let posted = try XCTUnwrap(post.postedAt)
        XCTAssertEqual(posted.timeIntervalSince1970, 1_795_600_800, accuracy: 0.5)

        XCTAssertEqual(post.relativeDateLabel(now: posted.addingTimeInterval(30)), "just now")
        XCTAssertEqual(post.relativeDateLabel(now: posted.addingTimeInterval(5 * 60)), "5 min ago")
        XCTAssertEqual(post.relativeDateLabel(now: posted.addingTimeInterval(3 * 3600)), "3 h ago")
        XCTAssertEqual(post.relativeDateLabel(now: posted.addingTimeInterval(25 * 3600)), "yesterday")
        XCTAssertEqual(post.relativeDateLabel(now: posted.addingTimeInterval(4 * 86400 + 3600)), "4 days ago")
        XCTAssertNil(post.relativeDateLabel(now: posted.addingTimeInterval(5 * 86400)))
        XCTAssertNil(post.relativeDateLabel(now: posted.addingTimeInterval(-60)))
    }

    func testAPostWithoutAReadableDateHasNoAge() throws {
        let post = try decode(#"{"component": "post", "date": "soon, maybe"}"#)

        XCTAssertNil(post.postedAt)
        XCTAssertNil(post.relativeDateLabel())
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

    func testTheSharedPoolIsThePostsAlone() async throws {
        let posts = try await client.feedPosts()
        let pool = await client.feedPool()

        XCTAssertEqual(pool.map(\.id), FeedPool.items(in: posts).map(\.id))
    }

    func testTheOldFeedPageStaysOutOfThePageIndex() {
        XCTAssertTrue(StorySlug.isHiddenFromPageIndex("feed-xml_html", component: "page"))
        XCTAssertFalse(StorySlug.isHiddenFromPageIndex("cv", component: "page"))
    }

    func testASoundCloudTrackJoinsThePoolAsAListenHandoff() throws {
        let post = try decode(
            """
            {"_uid": "p1", "component": "post",
             "music": [{"_uid": "m1", "component": "music_player", "source": "soundcloud",
                        "src": "https://soundcloud.com/te3shay/sets/star-heart-edits-pt1",
                        "title": "star heart edits"}]}
            """
        )
        let items = FeedPool.items(in: [FeedPost(id: "p1", slug: "a", fullSlug: "feed/a", blok: post)])

        XCTAssertEqual(items.count, 1)
        guard case .music(let title, _, _, let track, let listenURL) = items[0].kind else {
            return XCTFail("soundcloud should still be a music item")
        }
        XCTAssertEqual(title, "star heart edits")
        XCTAssertNil(track)
        XCTAssertEqual(listenURL?.host, "soundcloud.com")
    }

    func testAVideoInAPostIsAVideoAndNoImage() throws {
        let post = try decode(
            """
            {"component": "post", "format": "1/1",
             "images": [
               {"_uid": "v1", "component": "post_image", "image": {"filename": "https://a.storyblok.com/f/281211/x/abc123/clip.mp4"}},
               {"_uid": "i1", "component": "post_image", "image": {"filename": "\(asset)"}}
             ]}
            """
        )

        XCTAssertEqual(post.images[0].videoURL?.lastPathComponent, "clip.mp4")
        XCTAssertNil(post.images[0].filename)
        XCTAssertNil(post.images[1].videoURL)
        XCTAssertEqual(post.images[1].filename, asset)
    }

    func testAPostVideoJoinsThePoolAsAClip() throws {
        let post = try decode(
            """
            {"_uid": "p1", "component": "post", "caption": "harbour, moving",
             "images": [
               {"_uid": "v1", "component": "post_image", "image": {"filename": "https://a.storyblok.com/f/281211/x/abc123/clip.mp4"}},
               {"_uid": "i1", "component": "post_image", "image": {"filename": "\(asset)"}}
             ]}
            """
        )
        let items = FeedPool.items(in: [FeedPost(id: "p1", slug: "a", fullSlug: "feed/a", blok: post)])

        XCTAssertEqual(items.count, 2)
        guard case .video(let poster, let caption, let url) = items[0].kind else {
            return XCTFail("the video should be a clip")
        }
        XCTAssertNil(poster)
        XCTAssertEqual(caption, "harbour, moving")
        XCTAssertEqual(url?.lastPathComponent, "clip.mp4")
        XCTAssertEqual(items[1].kind, .image(filename: asset))
    }

    private func decode(_ json: String) throws -> PostBlok {
        try JSONDecoder().decode(PostBlok.self, from: Data(json.utf8))
    }
}

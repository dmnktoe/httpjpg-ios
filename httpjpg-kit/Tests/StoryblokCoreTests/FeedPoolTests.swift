import XCTest

@testable import StoryblokCore

final class FeedPoolTests: XCTestCase {
    private let client = ContentClient(
        configuration: StoryblokConfiguration(accessToken: "mock", source: .mock)
    )

    private let asset = "https://a.storyblok.com/f/281211/3000x2000/abcdef123456"

    func testTheFeedPageYieldsImagesTracksAndClips() async throws {
        let page = try await client.page(slug: StorySlug.feed)
        let items = FeedPool.items(in: page.body)

        XCTAssertEqual(items.filter { if case .image = $0.kind { return true }; return false }.count, 6)
        XCTAssertEqual(items.filter { if case .music = $0.kind { return true }; return false }.count, 2)
        XCTAssertEqual(items.filter { if case .video = $0.kind { return true }; return false }.count, 1)

        guard case .music(let title, let artist, let artwork, let track, let listenURL) = items.first(where: {
            if case .music = $0.kind { return true }
            return false
        })?.kind else {
            return XCTFail("the feed fixture should carry a playable track")
        }
        XCTAssertEqual(title, "mega mashup (mock)")
        XCTAssertEqual(artist, "te3shay")
        XCTAssertNotNil(artwork)
        XCTAssertNotNil(track)
        XCTAssertNil(listenURL)
    }

    func testImagesNestedInGridsAreFoundInDocumentOrder() throws {
        let bloks = try decode(
            """
            [
              {"component": "headline", "text": "no picture here"},
              {"component": "grid", "items": [
                {"component": "grid_item", "content": [
                  {"component": "image", "image": {"filename": "\(asset)/one.jpg"}}
                ]},
                {"component": "grid_item", "content": [
                  {"component": "music_player", "source": "mp3",
                   "src": "https://cdn.httpjpg.com/music/mashup.wav",
                   "title": "mashup", "artist": "te3shay"}
                ]}
              ]}
            ]
            """
        )

        let items = FeedPool.items(in: bloks)
        XCTAssertEqual(items.count, 2)
        guard case .image(let filename) = items[0].kind else {
            return XCTFail("first item should be the image")
        }
        XCTAssertEqual(filename, "\(asset)/one.jpg")
        guard case .music(let title, _, _, let track, _) = items[1].kind else {
            return XCTFail("second item should be the track")
        }
        XCTAssertEqual(title, "mashup")
        XCTAssertEqual(track?.streamURL.host, "cdn.httpjpg.com")
    }

    func testASoundCloudPlayerBecomesAListenHandoff() throws {
        let bloks = try decode(
            """
            [{"component": "music_player", "source": "soundcloud",
              "src": "https://soundcloud.com/te3shay/sets/star-heart-edits-pt1",
              "title": "star heart edits"}]
            """
        )

        let items = FeedPool.items(in: bloks)
        XCTAssertEqual(items.count, 1)
        guard case .music(_, _, _, let track, let listenURL) = items[0].kind else {
            return XCTFail("soundcloud should still be a music item")
        }
        XCTAssertNil(track)
        XCTAssertEqual(listenURL?.host, "soundcloud.com")
    }

    func testAVideoWithoutAPosterKeepsItsCaption() throws {
        let bloks = try decode(
            """
            [{"component": "video", "source": "native",
              "video": {"filename": "https://cdn.httpjpg.com/feed/clip.mp4"},
              "caption": {"type": "doc", "content": [
                {"type": "paragraph", "content": [{"type": "text", "text": "live on display"}]}
              ]}}]
            """
        )

        let items = FeedPool.items(in: bloks)
        XCTAssertEqual(items.count, 1)
        guard case .video(let poster, let caption) = items[0].kind else {
            return XCTFail("expected a video item")
        }
        XCTAssertNil(poster)
        XCTAssertEqual(caption, "live on display")
    }

    func testEmptyMusicAndVideoBloksAreLeftOut() throws {
        let bloks = try decode(
            """
            [
              {"component": "music_player", "source": "mp3"},
              {"component": "video", "source": "native"},
              {"component": "callout", "body": "xD"},
              {"component": "marquee", "text": "☆+♡"}
            ]
            """
        )

        XCTAssertTrue(FeedPool.items(in: bloks).isEmpty)
    }

    func testSlideshowsContributeEveryFrame() throws {
        let bloks = try decode(
            """
            [{"component": "slideshow", "images": [
              {"filename": "\(asset)/one.jpg"},
              {"filename": "\(asset)/two.jpg"}
            ]}]
            """
        )

        XCTAssertEqual(FeedPool.items(in: bloks).count, 2)
    }

    private func decode(_ json: String) throws -> [PortfolioBlok] {
        try JSONDecoder().decode([PortfolioBlok].self, from: Data(json.utf8))
    }
}

import XCTest

@testable import DesignSystem

final class EmbedVideoSurfaceTests: XCTestCase {
    func testYouTubeAcceptsABareVideoId() {
        XCTAssertEqual(
            EmbedVideoSurface.videoID(source: .youtube, from: "dQw4w9WgXcQ"),
            "dQw4w9WgXcQ"
        )
    }

    func testYouTubeReadsWatchShareAndEmbedUrls() {
        let urls = [
            "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            "https://youtu.be/dQw4w9WgXcQ",
            "https://www.youtube.com/embed/dQw4w9WgXcQ",
            "https://www.youtube.com/shorts/dQw4w9WgXcQ",
            "https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=30",
        ]

        for url in urls {
            XCTAssertEqual(
                EmbedVideoSurface.videoID(source: .youtube, from: url),
                "dQw4w9WgXcQ",
                url
            )
        }
    }

    func testYouTubeRejectsJunk() {
        XCTAssertNil(EmbedVideoSurface.videoID(source: .youtube, from: ""))
        XCTAssertNil(EmbedVideoSurface.videoID(source: .youtube, from: "https://example.com/video"))
        XCTAssertNil(EmbedVideoSurface.videoID(source: .youtube, from: "tooshort"))
    }

    func testVimeoAcceptsABareNumericId() {
        XCTAssertEqual(EmbedVideoSurface.videoID(source: .vimeo, from: "22439234"), "22439234")
    }

    func testVimeoReadsPageAndPlayerUrls() {
        let urls = [
            "https://vimeo.com/22439234",
            "https://player.vimeo.com/video/22439234",
            "https://vimeo.com/video/22439234",
        ]

        for url in urls {
            XCTAssertEqual(
                EmbedVideoSurface.videoID(source: .vimeo, from: url),
                "22439234",
                url
            )
        }
    }

    func testYouTubePlayerUrlMirrorsTheWebEmbedParams() throws {
        let url = try XCTUnwrap(
            EmbedVideoSurface.playerURL(
                source: .youtube,
                from: "https://youtu.be/dQw4w9WgXcQ",
                autoPlays: true,
                loops: true,
                isMuted: true,
                showsControls: false
            )
        )

        XCTAssertEqual(url.host, "www.youtube.com")
        XCTAssertEqual(url.path, "/embed/dQw4w9WgXcQ")

        let items = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        XCTAssertEqual(value("autoplay", in: items), "1")
        XCTAssertEqual(value("loop", in: items), "1")
        XCTAssertEqual(value("mute", in: items), "1")
        XCTAssertEqual(value("controls", in: items), "0")
        XCTAssertEqual(value("playsinline", in: items), "1")
        // YouTube only honours loop when the same id is also the playlist.
        XCTAssertEqual(value("playlist", in: items), "dQw4w9WgXcQ")
    }

    func testVimeoPlayerUrlMirrorsTheWebEmbedParams() throws {
        let url = try XCTUnwrap(
            EmbedVideoSurface.playerURL(
                source: .vimeo,
                from: "https://vimeo.com/22439234",
                autoPlays: false,
                loops: true,
                isMuted: false,
                showsControls: true
            )
        )

        XCTAssertEqual(url.host, "player.vimeo.com")
        XCTAssertEqual(url.path, "/video/22439234")

        let items = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        XCTAssertEqual(value("autoplay", in: items), "0")
        XCTAssertEqual(value("loop", in: items), "1")
        XCTAssertEqual(value("muted", in: items), "0")
        XCTAssertEqual(value("controls", in: items), "1")
        XCTAssertEqual(value("playsinline", in: items), "1")
    }

    func testPlayerUrlReturnsNilWhenTheIdCannotBeParsed() {
        XCTAssertNil(
            EmbedVideoSurface.playerURL(
                source: .youtube,
                from: "https://example.com/not-a-video"
            )
        )
    }

    private func value(_ name: String, in items: [URLQueryItem]) -> String? {
        items.first { $0.name == name }?.value
    }
}

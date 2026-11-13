import StoryblokCore
import XCTest

@testable import TVFeature

final class TVClipTests: XCTestCase {
    func testOnlyAVideoWithAnAddressBecomesAClip() throws {
        let url = try XCTUnwrap(URL(string: "https://cdn.httpjpg.com/feed/clip.mp4"))

        let clip = TVClip(item: FeedPool.Item(id: "a", kind: .video(poster: "still.png", caption: "live", url: url)))
        XCTAssertEqual(clip?.url, url)
        XCTAssertEqual(clip?.poster, "still.png")
        XCTAssertEqual(clip?.caption, "live")

        XCTAssertNil(TVClip(item: FeedPool.Item(id: "b", kind: .video(poster: "still.png", caption: nil, url: nil))))
        XCTAssertNil(TVClip(item: FeedPool.Item(id: "c", kind: .image(filename: "frame.jpg"))))
    }

    func testAWorkYieldsOneClipPerVideo() {
        let work = WorkItem(
            id: "work-1",
            slug: "kiosk",
            fullSlug: "work/kiosk",
            title: "kiosk",
            thumbnailURL: nil,
            imageFilenames: ["https://a.storyblok.com/f/1/still.jpg"],
            media: [
                WorkMedia(filename: "https://a.storyblok.com/f/1/still.jpg", isVideo: false),
                WorkMedia(filename: "https://a.storyblok.com/f/1/film.mp4", isVideo: true),
            ],
            isDraft: false,
            isExternal: false,
            externalURL: nil,
            date: nil
        )

        XCTAssertEqual(TVClip.clips(of: work).map(\.url.lastPathComponent), ["film.mp4"])
        XCTAssertEqual(TVGalleryFrame.frames(of: work).count, 1)
    }
}

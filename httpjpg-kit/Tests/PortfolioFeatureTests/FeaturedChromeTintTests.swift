import Foundation
import StoryblokCore
import XCTest

@testable import PortfolioFeature

final class FeaturedChromeTintTests: XCTestCase {
    func testNormalizesProtocolRelativeStoryblokURLs() throws {
        let raw = try XCTUnwrap(URL(string: "//a.storyblok.com/f/123/image.jpg"))
        let normalized = try XCTUnwrap(FeaturedChromeTint.normalized(raw))
        XCTAssertEqual(normalized.scheme, "https")
        XCTAssertEqual(normalized.host, "a.storyblok.com")
    }

    func testKeepsAbsoluteHTTPS() throws {
        let raw = try XCTUnwrap(URL(string: "https://a.storyblok.com/f/123/image.jpg"))
        XCTAssertEqual(FeaturedChromeTint.normalized(raw), raw)
    }

    func testRejectsFileURLs() throws {
        XCTAssertNil(FeaturedChromeTint.normalized(URL(fileURLWithPath: "/tmp/x.jpg")))
    }

    func testSampleURLFromWorkItemPrefersMidSizeStill() throws {
        let filename = "https://a.storyblok.com/f/1/1200x800/x/hero.jpg"
        let item = WorkItem(
            id: "1",
            slug: "hero",
            fullSlug: "work/hero",
            title: "Hero",
            thumbnailURL: URL(string: ImageService.Preset.thumb(filename)),
            imageFilenames: [filename],
            isDraft: false,
            isExternal: false,
            externalURL: nil,
            date: nil,
            tags: []
        )
        let url = try XCTUnwrap(FeaturedChromeTint.sampleURL(for: item))
        XCTAssertTrue(url.absoluteString.contains("/m/720x0/"), url.absoluteString)
        XCTAssertEqual(url.scheme, "https")
    }

    func testSampleURLSkipsVideoFilenames() throws {
        let video = "https://a.storyblok.com/f/1/video.mp4"
        let still = "https://a.storyblok.com/f/1/800x600/x/still.jpg"
        let item = WorkItem(
            id: "1",
            slug: "clip",
            fullSlug: "work/clip",
            title: "Clip",
            thumbnailURL: nil,
            imageFilenames: [video, still],
            isDraft: false,
            isExternal: false,
            externalURL: nil,
            date: nil,
            tags: []
        )
        let url = try XCTUnwrap(FeaturedChromeTint.sampleURL(for: item))
        XCTAssertTrue(url.absoluteString.contains("still.jpg"))
        XCTAssertFalse(url.absoluteString.contains("video.mp4"))
    }
}

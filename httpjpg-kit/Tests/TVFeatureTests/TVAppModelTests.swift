import StoryblokCore
import TopShelfFeature
import XCTest

@testable import TVFeature

@MainActor
final class TVAppModelTests: XCTestCase {
    private func model() -> TVAppModel {
        TVAppModel(configuration: StoryblokConfiguration(accessToken: "mock", source: .mock))
    }

    func testLoadingPutsProjectsAndWebsitesOnOneWall() async {
        let model = model()
        await model.load()

        XCTAssertTrue(model.isLoaded)
        XCTAssertEqual(model.items.count, 5)
        XCTAssertTrue(model.items.contains { $0.isExternal || $0.sliceTags.contains("Websites") })
    }

    func testGalleryHoldsEveryStillOfEveryWork() async {
        let model = model()
        await model.load()

        XCTAssertEqual(model.galleryFrames.count, 8)
        XCTAssertEqual(Set(model.galleryFrames.map(\.id)).count, model.galleryFrames.count)
    }

    func testTheFeedSplitsIntoTracksAndClips() async {
        let model = model()
        XCTAssertFalse(model.isFeedLoaded)

        await model.loadFeed()

        XCTAssertTrue(model.isFeedLoaded)
        // The fixture holds one playable file and one SoundCloud link, which has no stream.
        XCTAssertEqual(model.tracks.map(\.title), ["mega mashup (mock)"])
        XCTAssertEqual(model.clips.count, 1)
        XCTAssertEqual(model.clips.first?.url.pathExtension, "mp4")
    }

    func testFreshContentIsNotReloaded() async {
        let model = model()
        await model.load()
        let frames = model.galleryFrames

        await model.refreshIfStale()

        XCTAssertEqual(model.galleryFrames, frames)
    }

    func testAStaleIndexReloadsButKeepsTheRunningGalleryOrder() async {
        let model = model()
        await model.load()
        let frames = model.galleryFrames

        await model.refreshIfStale(now: Date().addingTimeInterval(ContentClient.cacheDuration + 1))

        XCTAssertTrue(model.isLoaded)
        XCTAssertEqual(model.galleryFrames, frames)
    }

    func testALinkToAnUnknownWorkDoesNotFireOnALaterRefresh() async throws {
        let model = model()
        model.open(try XCTUnwrap(TVDeepLink.work(slug: "no-such-work")))

        await model.load()
        await model.refreshIfStale(now: Date().addingTimeInterval(ContentClient.cacheDuration + 1))

        XCTAssertTrue(model.path.isEmpty)
    }

    func testYearGroupsRunNewestFirst() async {
        let model = model()
        await model.load()

        let years = model.groups.map(\.year).filter { $0 != WorkYearGroup.undatedYear }

        XCTAssertEqual(years, years.sorted(by: >))
    }

    func testTopShelfLinkOpensTheWorkOnceTheIndexHasLoaded() async throws {
        let model = model()
        model.tab = .gallery
        let url = try XCTUnwrap(TVDeepLink.work(slug: "kiosk"))

        model.open(url)
        XCTAssertTrue(model.path.isEmpty)

        await model.load()

        XCTAssertEqual(model.path.map(\.slug), ["kiosk"])
        XCTAssertEqual(model.tab, .works)
    }

    func testUnknownLinkLeavesThePathAlone() async throws {
        let model = model()
        await model.load()

        model.open(try XCTUnwrap(URL(string: "httpjpg://page/about")))
        model.open(try XCTUnwrap(TVDeepLink.work(slug: "no-such-work")))

        XCTAssertTrue(model.path.isEmpty)
    }
}

import UIKit
import XCTest

@testable import StoryblokContent

final class MockContentTests: XCTestCase {
    private let client = ContentClient(
        configuration: StoryblokConfiguration(accessToken: "mock", source: .mock)
    )

    func testWorkIndexComesFromTheFixtures() async throws {
        let collection = try await client.workIndex()

        XCTAssertEqual(collection.projects.count, 4)
        XCTAssertEqual(collection.websites.count, 1)
        XCTAssertEqual(collection.projects.first?.slug, "atlas-der-nebenstrassen")
        XCTAssertEqual(collection.websites.first?.isExternal, true)
        XCTAssertNotNil(collection.projects.first?.date)
        XCTAssertFalse(collection.projects.first?.imageFilenames.isEmpty ?? true)
    }

    func testEveryIndexedWorkAlsoResolvesAsADetail() async throws {
        let collection = try await client.workIndex()

        for item in collection.projects + collection.websites {
            let detail = try await client.workDetail(slug: item.slug)
            XCTAssertEqual(detail.slug, item.slug)
            XCTAssertFalse(detail.title.isEmpty)
        }
    }

    func testADetailCarriesItsBloks() async throws {
        let detail = try await client.workDetail(slug: "nachtbus")

        XCTAssertEqual(detail.title, "Nachtbus")
        XCTAssertNotNil(detail.date)
        XCTAssertNotNil(detail.dateEnd)
        XCTAssertTrue(detail.body.contains { $0.component == "video" })
        XCTAssertTrue(detail.body.contains { $0.component == "marquee" })
    }

    func testTheConfigStoryFeedsTheMenu() async {
        let config = await client.siteConfig()

        XCTAssertEqual(config.headerMenu.map(\.variant), [.projects, .websites])
        XCTAssertEqual(config.seoTitle?.contains("mock"), true)
        XCTAssertFalse(config.widgets.isDiscordEnabled)
        XCTAssertNotNil(config.footer?.copyrightText)
    }

    func testThePageIndexHidesConfigAndHome() async throws {
        let pages = try await client.pageIndex()

        XCTAssertEqual(pages.map(\.slug), ["about", "imprint", "feed-xml_html"])
    }

    func testAPageCarriesItsBloks() async throws {
        let page = try await client.page(slug: "about")

        XCTAssertEqual(page.title, "About")
        XCTAssertTrue(page.body.contains { $0.component == "work_list" })
    }

    func testWorkListRelationsResolveInTheOrderTheyWereAsked() async throws {
        let collection = try await client.workIndex()
        let requested = Array(collection.projects.prefix(3).map(\.id).reversed())

        let stories = try await client.workStories(byUUIDs: requested)

        XCTAssertEqual(stories.map { $0.uuid.uuidString }, requested)
    }

    func testAnUnknownStoryIsNotFound() async {
        do {
            _ = try await client.workDetail(slug: "not-a-real-work")
            XCTFail("expected the fixture provider to answer 404")
        } catch {
            XCTAssertTrue((error as? ContentError)?.isNotFound ?? false)
        }
    }

    func testAssetRequestsAnswerWithAPlaceholderOfTheRequestedSize() async throws {
        let collection = try await client.workIndex()
        let filename = try XCTUnwrap(collection.projects.first?.imageFilenames.first)
        let url = try XCTUnwrap(URL(string: ImageService.Preset.thumb(filename)))

        let (data, response) = try await URLSession.shared.data(from: url)

        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        let image = try XCTUnwrap(UIImage(data: data))
        XCTAssertEqual(image.size.width, 200)
        XCTAssertEqual(image.size.height, 133)
    }

    func testAudioAssetsAnswerWithAPlayableTone() async throws {
        let page = try await client.workDetail(slug: "tape-loop")
        let player = try XCTUnwrap(page.body.compactMap { blok -> MusicPlayerBlok? in
            guard case .musicPlayer(let player) = blok else { return nil }
            return player
        }.first)
        let url = try XCTUnwrap(player.track?.streamURL)

        let (data, response) = try await URLSession.shared.data(from: url)

        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertEqual(data.prefix(4), Data("RIFF".utf8))
    }

    func testVideoAssetsAreTheOneThingTheProviderCannotFake() async throws {
        let url = URL(string: "https://a.storyblok.com/f/1/1920x1080/x/clip.mp4")!

        let (_, response) = try await URLSession.shared.data(from: url)

        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 404)
    }

    func testASmallerPageSizeReturnsFewerStories() async throws {
        let collection = try await client.workIndex(perPage: 2)
        let pages = try await client.pageIndex(perPage: 1)

        XCTAssertEqual(collection.projects.count + collection.websites.count, 2)
        XCTAssertEqual(pages.map(\.slug), ["about"])
    }

    func testOnlyStoryblokTrafficIsIntercepted() {
        XCTAssertTrue(MockContentFixtures.handles(URL(string: "https://api.storyblok.com/v2/cdn/stories")))
        XCTAssertTrue(MockContentFixtures.handles(URL(string: "https://a.storyblok.com/f/1/x/p.jpg")))
        XCTAssertTrue(MockContentFixtures.handles(URL(string: "https://app.storyblokchina.cn/v2/cdn/stories")))
        XCTAssertFalse(MockContentFixtures.handles(URL(string: "https://www.httpjpg.com/api/discord")))
        XCTAssertFalse(MockContentFixtures.handles(URL(string: "https://storyblok.com.example.test/stories")))
        XCTAssertFalse(MockContentFixtures.handles(URL(string: "file:///tmp/stories.json")))
    }
}

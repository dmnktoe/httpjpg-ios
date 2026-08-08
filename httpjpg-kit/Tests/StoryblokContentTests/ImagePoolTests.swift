import XCTest

@testable import StoryblokContent

final class ImagePoolTests: XCTestCase {
    private let client = ContentClient(
        configuration: StoryblokConfiguration(accessToken: "mock", source: .mock)
    )

    func testTheFeedPageYieldsItsFrames() async throws {
        let page = try await client.page(slug: StorySlug.feed)

        let filenames = ImagePool.filenames(in: page.body)

        XCTAssertEqual(filenames.count, 6)
        XCTAssertTrue(filenames.allSatisfy { ImageService.isStoryblokAsset($0) })
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
                  {"component": "image", "image": {"filename": "\(asset)/two.jpg"}}
                ]}
              ]},
              {"component": "section", "content": [
                {"component": "container", "body": [
                  {"component": "image", "image": {"filename": "\(asset)/three.jpg"}}
                ]}
              ]}
            ]
            """
        )

        XCTAssertEqual(
            ImagePool.filenames(in: bloks),
            ["\(asset)/one.jpg", "\(asset)/two.jpg", "\(asset)/three.jpg"]
        )
    }

    func testSlideshowsContributeEveryFrame() throws {
        let bloks = try decode(
            """
            [
              {"component": "slideshow", "images": [
                {"filename": "\(asset)/one.jpg"},
                {"filename": "\(asset)/two.jpg"}
              ]}
            ]
            """
        )

        XCTAssertEqual(ImagePool.filenames(in: bloks).count, 2)
    }

    func testVideosEmptyAssetsAndRepeatsAreLeftOut() throws {
        let bloks = try decode(
            """
            [
              {"component": "image", "image": {"filename": "\(asset)/one.jpg"}},
              {"component": "image", "image": {"filename": "\(asset)/one.jpg"}},
              {"component": "image", "image": {"filename": ""}},
              {"component": "image", "image": {"filename": "\(asset)/clip.mp4"}},
              {"component": "video", "video": {"filename": "\(asset)/clip.mp4"}}
            ]
            """
        )

        XCTAssertEqual(ImagePool.filenames(in: bloks), ["\(asset)/one.jpg"])
    }

    private let asset = "https://a.storyblok.com/f/281211/3000x2000/abcdef123456"

    private func decode(_ json: String) throws -> [PortfolioBlok] {
        try JSONDecoder().decode([PortfolioBlok].self, from: Data(json.utf8))
    }
}

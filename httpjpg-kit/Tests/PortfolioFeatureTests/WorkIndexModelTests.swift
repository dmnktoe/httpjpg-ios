import StoryblokCore
import XCTest

@testable import PortfolioFeature

@MainActor
final class WorkIndexModelTests: XCTestCase {
    private func makeModel() async -> WorkIndexModel {
        let model = WorkIndexModel(
            client: ContentClient(
                configuration: StoryblokConfiguration(accessToken: "mock", source: .mock)
            )
        )
        await model.load()
        return model
    }

    func testAnUnknownTagDoesNotEmptyTheList() async {
        let model = await makeModel()
        let before = model.visibleItems.map(\.id)

        model.select(tag: "a-tag-nothing-carries")

        XCTAssertNil(model.activeTag)
        XCTAssertEqual(model.visibleItems.map(\.id), before)
    }

    func testSwitchingVariantClearsTheSelectedTag() async {
        let model = await makeModel()
        model.select(tag: model.availableTags.first)
        model.select(variant: .websites)

        XCTAssertNil(model.selectedTag)
        XCTAssertNil(model.activeTag)
    }

    func testSelectingATagKeepsOnlyWorksThatCarryIt() async {
        let model = await makeModel()
        guard let tag = model.availableTags.first else {
            return
        }

        model.select(tag: tag)

        XCTAssertEqual(model.activeTag, tag)
        XCTAssertFalse(model.visibleItems.isEmpty)
        XCTAssertTrue(model.visibleItems.allSatisfy { $0.tags.contains(tag) })
    }
}

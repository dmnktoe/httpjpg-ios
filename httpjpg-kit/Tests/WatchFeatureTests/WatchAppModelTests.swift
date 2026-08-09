import StoryblokCore
import XCTest

@testable import WatchFeature

@MainActor
final class WatchAppModelTests: XCTestCase {
    private func model() -> WatchAppModel {
        WatchAppModel(configuration: StoryblokConfiguration(accessToken: "mock", source: .mock))
    }

    func testLoadingFillsTheProjectsSlice() async {
        let model = model()
        await model.load()

        XCTAssertTrue(model.isLoaded)
        XCTAssertEqual(model.items.count, 4)
        XCTAssertFalse(model.groups.isEmpty)
    }

    func testSwitchingSliceSwapsTheItems() async {
        let model = model()
        await model.load()

        model.select(variant: .websites)

        XCTAssertEqual(model.items.count, 1)
        XCTAssertEqual(model.items.first?.isExternal, true)
    }

    func testYearGroupsRunNewestFirst() async {
        let model = model()
        await model.load()

        let years = model.groups.map(\.year).filter { $0 != WorkYearGroup.undatedYear }

        XCTAssertEqual(years, years.sorted(by: >))
    }

    func testShufflePushesAWorkFromTheCurrentSlice() async {
        let model = model()
        await model.load()

        model.shuffle()

        XCTAssertEqual(model.path.count, 1)
        XCTAssertTrue(model.items.contains { $0.id == model.path.first?.id })
    }

    func testShuffleOnAnEmptyIndexKeepsThePathClosed() {
        let model = model()

        model.shuffle()

        XCTAssertTrue(model.path.isEmpty)
    }
}

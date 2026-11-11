import WidgetKit
import XCTest

@testable import WidgetFeature

final class WorkGridLayoutTests: XCTestCase {
    private let families: [WidgetFamily] = [.systemMedium, .systemLarge, .systemExtraLarge]

    func testEveryFamilyFillsWholeRows() {
        XCTAssertEqual(WorkGridLayout.tiles(for: .systemMedium), 4)
        XCTAssertEqual(WorkGridLayout.tiles(for: .systemLarge), 6)
        XCTAssertEqual(WorkGridLayout.tiles(for: .systemExtraLarge), 12)
    }

    func testThePlaceholderCoversTheLargestGrid() {
        for family in families {
            XCTAssertLessThanOrEqual(WorkGridLayout.tiles(for: family), WorkGridLayout.maximumTiles)
        }
        XCTAssertEqual(WorkGridEntry.placeholder.items.count, WorkGridLayout.maximumTiles)
    }

    func testATileIsOneColumnOfTheDisplayWidth() {
        XCTAssertEqual(WorkGridLayout.tileWidth(for: .systemLarge, displayWidth: 330), 110)
        XCTAssertEqual(WorkGridLayout.tileWidth(for: .systemMedium, displayWidth: 0), 1)
    }
}

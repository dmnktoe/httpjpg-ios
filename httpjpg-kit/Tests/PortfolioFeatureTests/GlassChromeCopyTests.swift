import StoryblokCore
import XCTest

@testable import PortfolioFeature

@MainActor
final class GlassChromeCopyTests: XCTestCase {
    func testTabPillsKeepTheAuthoredLabels() {
        XCTAssertEqual(AppModel.Tab.work.label, "🎀 ୧ꔛꗃ˖ աօʀӄ")
        XCTAssertEqual(AppModel.Tab.info.label, "👊🐯  ᶤⓝƒ𝓸")
        XCTAssertEqual(AppModel.Tab.work.accessibilityLabel, "Work")
        XCTAssertEqual(AppModel.Tab.info.accessibilityLabel, "Info")
    }

    func testWorkFilterPillsKeepTheAuthoredLabels() {
        XCTAssertEqual(MenuLink.Variant.allVariants.map(\.rawValue), ["projects", "websites"])
        XCTAssertEqual(MenuLink.Variant.projects.filterLabel, "⇝ᵣₑcꫀₙₜ TH1𝓃𝑔S")
        XCTAssertEqual(MenuLink.Variant.websites.filterLabel, "⇝ᵣₑcꫀₙₜ ℘ɑׁׅ֮ᧁׁꫀׁׅܻ꯱ׁׅ֒")
        XCTAssertEqual(MenuLink.Variant.projects.accessibilityLabel, "Projects")
        XCTAssertEqual(MenuLink.Variant.websites.accessibilityLabel, "Websites")
    }
}

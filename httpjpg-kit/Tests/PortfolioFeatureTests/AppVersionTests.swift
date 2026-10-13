import XCTest

@testable import PortfolioFeature

final class AppVersionTests: XCTestCase {
    func testDisplayStringFormatsMarketingAndBuild() {
        let version = AppVersion(marketing: "1.0.0", build: "1")
        XCTAssertEqual(version.displayString, "v1.0.0 (1)")
    }

    func testCurrentReadsInfoDictionary() {
        let bundle = Bundle(for: AppVersionTests.self)
        _ = AppVersion.current(bundle: bundle)
        let synthetic = AppVersion(marketing: "2.1.0", build: "42")
        XCTAssertEqual(synthetic.marketing, "2.1.0")
        XCTAssertEqual(synthetic.build, "42")
    }
}

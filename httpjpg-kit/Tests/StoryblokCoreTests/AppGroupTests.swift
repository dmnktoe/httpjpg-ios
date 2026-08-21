import XCTest

@testable import StoryblokCore

final class AppGroupTests: XCTestCase {
    func testFallsBackWhenTheBundleDoesNotDeclareAGroup() {
        let bundle = Bundle(for: AppGroupTests.self)

        XCTAssertNil(bundle.object(forInfoDictionaryKey: AppGroup.InfoPlistKey.identifier))
        XCTAssertEqual(AppGroup.identifier(bundle), AppGroup.defaultIdentifier)
    }

    /// The test bundle carries no group entitlement, so every caller has to keep
    /// working off the per-process fallback.
    func testAMissingContainerYieldsNoCacheDirectory() {
        XCTAssertNil(AppGroup.cachesURL(AppGroup.CacheName.images, bundle: Bundle(for: AppGroupTests.self)))
    }
}

import XCTest

@testable import PortfolioFeature

final class RecentSearchesTests: XCTestCase {
    private func makeDefaults() -> UserDefaults {
        let name = "RecentSearchesTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    func testRememberDedupesCaseInsensitivelyAndKeepsNewestFirst() {
        let recents = RecentSearches(defaults: makeDefaults())
        recents.remember("blence")
        recents.remember("sentiment")

        XCTAssertEqual(recents.remember("  Blence "), ["Blence", "sentiment"])
        XCTAssertEqual(recents.all, ["Blence", "sentiment"])
    }

    func testRememberIgnoresBlankAndCapsTheList() {
        let recents = RecentSearches(defaults: makeDefaults())

        XCTAssertEqual(recents.remember("   "), [])

        for index in 0..<10 {
            recents.remember("query \(index)")
        }

        XCTAssertEqual(recents.all.count, RecentSearches.limit)
        XCTAssertEqual(recents.all.first, "query 9")
    }

    func testClearForgetsEverything() {
        let recents = RecentSearches(defaults: makeDefaults())
        recents.remember("blence")

        recents.clear()

        XCTAssertEqual(recents.all, [])
    }
}

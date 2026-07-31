import StoryblokContent
import UIKit
import XCTest

@testable import PortfolioFeature

@MainActor
final class QuickActionMenuTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_750_000_000)

    private func work(
        _ slug: String,
        daysAgo: Double?,
        tags: [String] = ["Projects"],
        isExternal: Bool = false
    ) -> WorkItem {
        WorkItem(
            id: slug,
            slug: slug,
            fullSlug: "work/" + slug,
            title: slug.uppercased(),
            thumbnailURL: nil,
            imageFilenames: [],
            isDraft: false,
            isExternal: isExternal,
            externalURL: nil,
            date: daysAgo.map { now.addingTimeInterval(-$0 * 86_400) },
            tags: tags
        )
    }

    private func collection(_ items: [WorkItem]) -> WorkCollection {
        WorkCollection(
            projects: items.filter { !$0.tags.contains("Websites") },
            websites: items.filter { $0.tags.contains("Websites") }
        )
    }

    func testListsTheThreeNewestWorksNewestFirst() {
        let items = QuickActionMenu.items(
            for: collection([
                work("older", daysAgo: 300),
                work("newest", daysAgo: 2),
                work("middle", daysAgo: 60),
                work("oldest", daysAgo: 900),
                work("second", daysAgo: 40),
            ]),
            now: now
        )

        XCTAssertEqual(items.prefix(3).map(\.localizedTitle), ["NEWEST", "SECOND", "MIDDLE"])
    }

    func testWorkEntryRoundTripsThroughUserInfo() {
        let items = QuickActionMenu.items(for: collection([work("atlas", daysAgo: 120)]), now: now)

        XCTAssertEqual(QuickAction(items[0]), .work(slug: "atlas", title: "ATLAS"))
        XCTAssertEqual(QuickAction(items[0])?.route?.slug, "atlas")
    }

    func testShuffleCarriesEverythingNotAlreadyListed() {
        let items = QuickActionMenu.items(
            for: collection([
                work("one", daysAgo: 1),
                work("two", daysAgo: 2),
                work("three", daysAgo: 3),
                work("four", daysAgo: 4),
                work("five", daysAgo: 5),
            ]),
            now: now
        )

        XCTAssertEqual(items.count, 4)
        XCTAssertEqual(QuickAction(items[3]), .shuffle(pool: ["four", "five"]))
    }

    func testShufflePoolStopsAtSixtySlugs() {
        let archive = (1...80).map { work("work-\($0)", daysAgo: Double($0)) }

        let items = QuickActionMenu.items(for: collection(archive), now: now)

        guard case .shuffle(let pool)? = QuickAction(items[3]) else {
            return XCTFail("expected a shuffle entry")
        }
        XCTAssertEqual(pool.count, 60)
        XCTAssertEqual(pool.first, "work-4")
    }

    func testDropsTheShuffleWhenTheArchiveHoldsNothingElse() {
        let items = QuickActionMenu.items(
            for: collection([
                work("one", daysAgo: 1),
                work("two", daysAgo: 2),
                work("three", daysAgo: 3),
            ]),
            now: now
        )

        XCTAssertEqual(items.count, 3)
    }

    func testFreshWorkIsMarkedInTheSubtitle() {
        let items = QuickActionMenu.items(
            for: collection([work("fresh", daysAgo: 3), work("stale", daysAgo: 400)]),
            now: now
        )

        XCTAssertEqual(items[0].localizedSubtitle?.hasPrefix("new"), true)
        XCTAssertEqual(items[1].localizedSubtitle?.hasPrefix("new"), false)
        XCTAssertNotNil(items[1].localizedSubtitle)
    }

    func testUndatedWorkFallsBackToItsTag() {
        let items = QuickActionMenu.items(
            for: collection([work("undated", daysAgo: nil, tags: ["Websites"])]),
            now: now
        )

        XCTAssertEqual(items[0].localizedSubtitle, "websites")
    }

    func testAWorkDatedInTheFutureIsNotFresh() {
        let items = QuickActionMenu.items(for: collection([work("ahead", daysAgo: -5)]), now: now)

        XCTAssertEqual(items[0].localizedSubtitle?.hasPrefix("new"), false)
    }

    func testAWorkInBothSlicesIsListedOnce() {
        let both = work("hybrid", daysAgo: 5, tags: ["Projects", "Websites"])
        let slices = WorkCollection(projects: [both], websites: [both])

        let items = QuickActionMenu.items(for: slices, now: now)

        XCTAssertEqual(items.map(\.localizedTitle), ["HYBRID"])
    }

    func testAnEmptyArchiveClearsTheMenu() {
        XCTAssertTrue(QuickActionMenu.items(for: .empty, now: now).isEmpty)
    }

    func testIgnoresShortcutItemsItDidNotCreate() {
        let foreign = UIApplicationShortcutItem(type: "com.example.other", localizedTitle: "Nope")

        XCTAssertNil(QuickAction(foreign))
    }

    func testEveryEntryReadsBackAsTheActionItEncodes() {
        let items = QuickActionMenu.items(
            for: collection([
                work("one", daysAgo: 1),
                work("two", daysAgo: 2),
                work("three", daysAgo: 3),
                work("four", daysAgo: 4),
            ]),
            now: now
        )

        XCTAssertEqual(items.compactMap(QuickAction.init).count, items.count)
        XCTAssertEqual(QuickAction(items[0]), .work(slug: "one", title: "ONE"))
        XCTAssertEqual(QuickAction(items[3]), .shuffle(pool: ["four"]))
    }
}

import UIKit
import XCTest

@testable import PortfolioFeature

@MainActor
final class QuickActionInboxTests: XCTestCase {
    private let inbox = QuickActionInbox.shared

    override func setUp() {
        super.setUp()
        _ = inbox.take()
    }

    override func tearDown() {
        _ = inbox.take()
        super.tearDown()
    }

    private func item(
        type: String = QuickAction.Kind.work.type,
        userInfo: [String: any NSSecureCoding]? = [QuickAction.UserInfoKey.slug: "atlas" as NSString]
    ) -> UIApplicationShortcutItem {
        UIApplicationShortcutItem(
            type: type,
            localizedTitle: "ATLAS",
            localizedSubtitle: nil,
            icon: nil,
            userInfo: userInfo
        )
    }

    func testAPostedActionWaitsUntilItIsTaken() {
        inbox.post(item())

        XCTAssertEqual(inbox.pending, .work(slug: "atlas", title: "atlas"))
        XCTAssertEqual(inbox.take(), .work(slug: "atlas", title: "atlas"))
    }

    func testTakingEmptiesTheInbox() {
        inbox.post(item())

        _ = inbox.take()

        XCTAssertNil(inbox.pending)
        XCTAssertNil(inbox.take())
    }

    func testForeignItemsNeverReachTheInbox() {
        XCTAssertFalse(inbox.post(item(type: "com.example.other")))
        XCTAssertNil(inbox.pending)
    }

    func testAWorkItemWithoutASlugIsDropped() {
        XCTAssertFalse(inbox.post(item(userInfo: nil)))
        XCTAssertNil(inbox.pending)
    }

    func testAnAcceptedItemReportsSuccessBackToUIKit() {
        XCTAssertTrue(inbox.post(item()))
    }

    func testTheNewestActionWins() {
        inbox.post(item())
        inbox.post(
            UIApplicationShortcutItem(
                type: QuickAction.Kind.shuffle.type,
                localizedTitle: "Shuffle",
                localizedSubtitle: nil,
                icon: nil,
                userInfo: [QuickAction.UserInfoKey.pool: ["one", "two"] as NSArray]
            )
        )

        XCTAssertEqual(inbox.pending, .shuffle(pool: ["one", "two"]))
    }
}

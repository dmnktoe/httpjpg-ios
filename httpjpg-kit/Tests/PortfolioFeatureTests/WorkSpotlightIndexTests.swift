import CoreSpotlight
import XCTest

@testable import PortfolioFeature

@MainActor
final class WorkSpotlightIndexTests: XCTestCase {
    func testASpotlightHitYieldsItsSlug() {
        let activity = NSUserActivity(activityType: CSSearchableItemActionType)
        activity.userInfo = [CSSearchableItemActivityIdentifier: "nachtbus"]

        XCTAssertEqual(WorkSpotlightIndex.slug(from: activity), "nachtbus")
    }

    func testAnUnrelatedActivityIsIgnored() {
        let activity = NSUserActivity(activityType: "com.yl33ly.httpjpg.something-else")
        activity.userInfo = [CSSearchableItemActivityIdentifier: "nachtbus"]

        XCTAssertNil(WorkSpotlightIndex.slug(from: activity))
    }

    func testTheInboxTakesAnActionDirectly() {
        let inbox = QuickActionInbox.shared
        _ = inbox.take()

        inbox.post(.work(slug: "atlas", title: "ATLAS"))

        XCTAssertEqual(inbox.take(), .work(slug: "atlas", title: "ATLAS"))
        XCTAssertNil(inbox.pending)
    }
}

import XCTest

@testable import StoryblokCore

final class RelatedWorkTests: XCTestCase {
    func testAStoryWithNoTagsHasNoNeighbours() {
        let current = item("atlas", tags: [])
        let neighbours = RelatedWork.neighbours(
            id: current.id,
            tagValues: current.tagValues,
            in: [current, item("kiosk", tags: ["swift"])]
        )
        XCTAssertTrue(neighbours.isEmpty)
    }

    /// `shader` is the only neighbour that shares the rare `swift` tag, so it
    /// ranks first. `a`/`b`/`c`/`site` all share equally common `web`; the
    /// remaining slots fill alphabetically among them (default limit is 3).
    func testScoresByTheRarityOfSharedTags() {
        let current = item("atlas", tags: ["swift", "web"])
        let rareTwin = item("shader", tags: ["swift"])
        let matches = RelatedWork.neighbours(
            id: current.id,
            tagValues: current.tagValues,
            in: [
                current,
                rareTwin,
                item("site", tags: ["web"]),
                item("a", tags: ["web"]),
                item("b", tags: ["web"]),
                item("c", tags: ["web"]),
            ]
        )
        XCTAssertEqual(matches.first?.item.slug, "shader")
        XCTAssertEqual(matches.first?.sharedTags, ["Swift"])
        XCTAssertEqual(matches.count, 3)
        XCTAssertTrue(
            matches.dropFirst().allSatisfy { $0.sharedTags == ["Web"] },
            "the common tag fills the remaining slots, never outranking the rare one"
        )
    }

    func testSkipsUnlistedWork() {
        let current = item("atlas", tags: ["swift"])
        let hidden = item("secret", tags: ["swift"], isListedInApp: false)
        let shown = item("kiosk", tags: ["swift"])
        let matches = RelatedWork.neighbours(
            id: current.id,
            tagValues: current.tagValues,
            in: [current, hidden, shown]
        )
        XCTAssertEqual(matches.map(\.item.slug), ["kiosk"])
    }

    func testCapsTheStripAtThree() {
        let current = item("atlas", tags: ["swift"])
        let pool = (0..<6).map { item("w\($0)", tags: ["swift"]) }
        let matches = RelatedWork.neighbours(
            id: current.id,
            tagValues: current.tagValues,
            in: [current] + pool
        )
        XCTAssertEqual(matches.count, 3)
    }

    private func item(
        _ slug: String,
        tags: [String],
        isListedInApp: Bool = true
    ) -> WorkItem {
        WorkItem(
            id: slug,
            slug: slug,
            fullSlug: "work/" + slug,
            title: slug,
            thumbnailURL: nil,
            imageFilenames: [],
            isDraft: false,
            isExternal: false,
            isListedInApp: isListedInApp,
            externalURL: nil,
            date: nil,
            tags: WorkTopicTag.labels(for: tags),
            tagValues: tags
        )
    }
}

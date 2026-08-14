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

    func testScoresByTheRarityOfSharedTags() {
        let current = item("atlas", tags: ["swift", "web"])
        let glslTwin = item("shader", tags: ["swift"])
        let webTwin = item("site", tags: ["web"])
        let matches = RelatedWork.neighbours(
            id: current.id,
            tagValues: current.tagValues,
            in: [
                current,
                glslTwin,
                webTwin,
                item("a", tags: ["web"]),
                item("b", tags: ["web"]),
                item("c", tags: ["web"]),
            ]
        )
        XCTAssertEqual(matches.map(\.item.slug), ["shader", "site"])
        XCTAssertEqual(matches[0].sharedTags, ["Swift"])
        XCTAssertEqual(matches[1].sharedTags, ["Web"])
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

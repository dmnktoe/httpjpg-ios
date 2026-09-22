import XCTest

@testable import StoryblokCore

final class WorkTopicTagTests: XCTestCase {
    func testCatalogValuesAreUnique() {
        let values = WorkTopicTag.catalog.map(\.value)
        XCTAssertEqual(Set(values).count, values.count)
    }

    func testCatalogLabelsAreUnique() {
        let labels = WorkTopicTag.catalog.map(\.label)
        XCTAssertEqual(Set(labels).count, labels.count)
    }

    func testFindsATagByItsStoredValue() {
        XCTAssertEqual(WorkTopicTag.named("typescript")?.label, "TypeScript")
        XCTAssertEqual(WorkTopicTag.named("typescript")?.group, .language)
        XCTAssertNil(WorkTopicTag.named("cobol"))
    }

    func testDropsValuesOutsideTheVocabulary() {
        XCTAssertEqual(
            WorkTopicTag.labels(for: ["typescript", "cobol", "react"]),
            ["TypeScript", "React"]
        )
    }

    func testDeduplicatesRepeatedValues() {
        XCTAssertEqual(WorkTopicTag.labels(for: ["react", "react"]), ["React"])
    }

    func testOrdersByGroupThenCatalogPosition() {
        XCTAssertEqual(
            WorkTopicTag.labels(for: ["vercel", "typescript", "frontend", "react"]),
            ["Frontend", "TypeScript", "React", "Vercel"]
        )
    }

    func testKeepsTheAuthoredCasingOnTheLabel() {
        XCTAssertEqual(
            WorkTopicTag.labels(for: ["ios", "macos", "next-js"]),
            ["Next.js", "iOS", "macOS"]
        )
    }
}

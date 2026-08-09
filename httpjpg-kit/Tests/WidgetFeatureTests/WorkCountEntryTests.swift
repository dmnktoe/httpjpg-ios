import StoryblokCore
import XCTest

@testable import WidgetFeature

final class WorkCountEntryTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin") ?? .gmt
        return calendar
    }()

    func testACollectionCountsBothVariantsAndItsYearSpan() throws {
        let entry = WorkCountEntry(
            date: .now,
            collection: WorkCollection(
                projects: [item(year: 2019), item(year: 2026), item(year: 2022)],
                websites: [item(year: 2021)]
            ),
            calendar: calendar
        )

        XCTAssertEqual(entry.projects, 3)
        XCTAssertEqual(entry.websites, 1)
        XCTAssertEqual(entry.total, 4)
        XCTAssertEqual(entry.span, "2019–2026")
    }

    func testTheStampIsPaddedToThreeDigits() {
        XCTAssertEqual(count(projects: 4).stamp, "004")
        XCTAssertEqual(count(projects: 42).stamp, "042")
        XCTAssertEqual(count(projects: 421).stamp, "421")
    }

    func testASingleYearReadsAsSince() throws {
        let entry = WorkCountEntry(
            date: .now,
            collection: WorkCollection(projects: [item(year: 2026)], websites: []),
            calendar: calendar
        )

        XCTAssertEqual(entry.span, "since 2026")
    }

    func testUndatedWorksStillCountButLeaveNoSpan() throws {
        let entry = WorkCountEntry(
            date: .now,
            collection: WorkCollection(projects: [item(year: nil), item(year: nil)], websites: []),
            calendar: calendar
        )

        XCTAssertEqual(entry.total, 2)
        XCTAssertNil(entry.span)
    }

    private func count(projects: Int) -> WorkCountEntry {
        WorkCountEntry(date: .now, projects: projects, websites: 0)
    }

    private func item(year: Int?) -> WorkItem {
        WorkItem(
            id: "work-\(year ?? 0)-\(UUID().uuidString)",
            slug: "work",
            fullSlug: "work/work",
            title: "work",
            thumbnailURL: nil,
            imageFilenames: [],
            isDraft: false,
            isExternal: false,
            externalURL: nil,
            date: year.flatMap {
                DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: $0, month: 6, day: 1).date
            },
            tags: []
        )
    }
}

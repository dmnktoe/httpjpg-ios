import StoryblokCore
import XCTest

@testable import TVFeature

final class TVFrameOfTheDayTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin") ?? .gmt
        return calendar
    }()

    private let frames: [TVGalleryFrame] = (1 ... 5).map { index in
        TVGalleryFrame(
            filename: "frame-\(index).jpg",
            item: WorkItem(
                id: "work-\(index)",
                slug: "work-\(index)",
                fullSlug: "work/work-\(index)",
                title: "work \(index)",
                thumbnailURL: nil,
                imageFilenames: ["frame-\(index).jpg"],
                isDraft: false,
                isExternal: false,
                externalURL: nil,
                date: nil
            )
        )
    }

    func testTheSameDayAlwaysPicksTheSameFrame() throws {
        XCTAssertEqual(
            TVFrameOfTheDay.index(for: try date(2026, 8, 5, hour: 7), count: 5, calendar: calendar),
            TVFrameOfTheDay.index(for: try date(2026, 8, 5, hour: 23), count: 5, calendar: calendar)
        )
    }

    func testConsecutiveDaysMoveOnByOneFrame() throws {
        let first = TVFrameOfTheDay.index(for: try date(2026, 8, 5), count: 5, calendar: calendar)
        let second = TVFrameOfTheDay.index(for: try date(2026, 8, 6), count: 5, calendar: calendar)

        XCTAssertEqual(second, (first + 1) % 5)
    }

    func testAnEmptyPoolHasNoOrder() throws {
        XCTAssertEqual(TVFrameOfTheDay.index(for: try date(2026, 8, 5), count: 0, calendar: calendar), 0)
        XCTAssertTrue(TVFrameOfTheDay.order([], on: try date(2026, 8, 5), calendar: calendar).isEmpty)
    }

    func testTheFrameOfTheDayLeadsAndNothingIsLost() throws {
        let day = try date(2026, 8, 5)
        let ordered = TVFrameOfTheDay.order(frames, on: day, calendar: calendar)

        XCTAssertEqual(ordered.first, frames[TVFrameOfTheDay.index(for: day, count: 5, calendar: calendar)])
        XCTAssertEqual(Set(ordered), Set(frames))
        XCTAssertEqual(ordered.count, frames.count)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) throws -> Date {
        try XCTUnwrap(
            calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))
        )
    }
}

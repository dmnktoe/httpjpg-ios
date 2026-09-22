import StoryblokCore
import XCTest

@testable import WidgetFeature

final class FrameOfTheDayProviderTests: XCTestCase {
    private let pool: [FeedPool.Item] = (1 ... 5).map { index in
        FeedPool.Item(id: "frame-\(index)", kind: .image(filename: "frame-\(index).jpg"))
    }

    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin") ?? .gmt
        return calendar
    }()

    func testTheSameDayAlwaysPicksTheSameFrame() throws {
        let morning = try date(2026, 8, 5, hour: 7)
        let evening = try date(2026, 8, 5, hour: 23)

        XCTAssertEqual(
            FrameOfTheDayProvider.item(for: morning, in: pool, calendar: calendar),
            FrameOfTheDayProvider.item(for: evening, in: pool, calendar: calendar)
        )
    }

    func testConsecutiveDaysMoveOnByOneFrame() throws {
        let first = FrameOfTheDayProvider.index(
            for: try date(2026, 8, 5),
            count: pool.count,
            calendar: calendar
        )
        let second = FrameOfTheDayProvider.index(
            for: try date(2026, 8, 6),
            count: pool.count,
            calendar: calendar
        )

        XCTAssertEqual(second, (first + 1) % pool.count)
    }

    func testAWeekOfDaysWalksTheWholePool() throws {
        let picked = try (5 ... 11).map { day in
            try XCTUnwrap(
                FrameOfTheDayProvider.item(
                    for: try date(2026, 8, day),
                    in: pool,
                    calendar: calendar
                )
            )
        }

        XCTAssertEqual(Set(picked.map(\.id)), Set(pool.map(\.id)))
    }

    func testAnEmptyPoolHasNoFrame() throws {
        XCTAssertNil(FrameOfTheDayProvider.item(for: try date(2026, 8, 5), in: [], calendar: calendar))
    }

    func testAMixedPoolCanLandOnATrack() throws {
        let mixed: [FeedPool.Item] = [
            FeedPool.Item(id: "photo", kind: .image(filename: "frame.jpg")),
            FeedPool.Item(
                id: "track",
                kind: .music(
                    title: "mega mashup",
                    artist: "te3shay",
                    artworkURL: "https://example.com/art.jpg",
                    track: nil,
                    listenURL: URL(string: "https://soundcloud.com/te3shay")
                )
            ),
        ]

        let item = try XCTUnwrap(
            FrameOfTheDayProvider.item(for: try date(2026, 8, 6), in: mixed, calendar: calendar)
        )
        XCTAssertEqual(item.id, mixed[FrameOfTheDayProvider.index(for: try date(2026, 8, 6), count: 2, calendar: calendar)].id)
    }

    func testDatesBeforeTheReferenceEpochStayInBounds() throws {
        let index = FrameOfTheDayProvider.index(
            for: try date(1994, 3, 17),
            count: pool.count,
            calendar: calendar
        )

        XCTAssertTrue((0 ..< pool.count).contains(index))
    }

    func testTheTimelineRunsToTheNextLocalMidnight() throws {
        let now = try date(2026, 8, 5, hour: 22, minute: 30)

        let next = FrameOfTheDayProvider.nextMidnight(after: now, calendar: calendar)

        XCTAssertEqual(next, try date(2026, 8, 6))
        XCTAssertEqual(calendar.component(.hour, from: next), 0)
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        hour: Int = 0,
        minute: Int = 0
    ) throws -> Date {
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )
        return try XCTUnwrap(components.date)
    }
}

import StoryblokCore
import XCTest

final class StatusOrderTests: XCTestCase {
    private struct Line {
        let id: String
        let isLive: Bool
        let date: Date?
    }

    func testLiveLinesLeadThenNewestThenUndated() {
        let lines = [
            Line(id: "letterboxd", isLive: false, date: Date(timeIntervalSince1970: 100)),
            Line(id: "reddit", isLive: false, date: nil),
            Line(id: "discord", isLive: true, date: nil),
            Line(id: "psn", isLive: false, date: Date(timeIntervalSince1970: 300)),
            Line(id: "lastfm", isLive: true, date: nil),
        ]

        let ordered = StatusOrder.sorted(lines, isLive: \.isLive, date: \.date)

        XCTAssertEqual(ordered.map(\.id), ["discord", "lastfm", "psn", "letterboxd", "reddit"])
    }

    func testTiesKeepTheFooterOrder() {
        let same = Date(timeIntervalSince1970: 500)
        let lines = [
            Line(id: "steam", isLive: false, date: nil),
            Line(id: "x", isLive: false, date: same),
            Line(id: "github", isLive: false, date: same),
            Line(id: "reddit", isLive: false, date: nil),
        ]

        let ordered = StatusOrder.sorted(lines, isLive: \.isLive, date: \.date)

        XCTAssertEqual(ordered.map(\.id), ["x", "github", "steam", "reddit"])
    }
}

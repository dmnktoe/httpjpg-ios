import StoryblokCore
import XCTest

@testable import TVFeature

final class TVStatusLineTests: XCTestCase {
    func testEveryAnsweringSourceBecomesOneLine() throws {
        let lines = TVStatusLine.lines(
            discord: try decode(#"{"status": "online", "activity": "figma"}"#),
            film: try decode(#"{"title": "stalker", "year": "1979", "rating": 4.5}"#),
            record: try decode(#"{"title": "selected ambient works", "artist": "aphex twin"}"#),
            trophy: try decode(#"{"name": "platinum", "game": "bloodborne"}"#),
            weather: try decode(#"{"temperature": 11.6, "condition": "overcast"}"#)
        )

        XCTAssertEqual(lines.map(\.text), [
            "discord: online · figma",
            "letterboxd: stalker 1979 ★★★★½",
            "discogs: aphex twin — selected ambient works",
            "psn: platinum · bloodborne",
            "weather: 12° overcast",
        ])
        XCTAssertEqual(Set(lines.map(\.id)).count, lines.count)
    }

    func testSilentAndEmptySourcesAreLeftOut() throws {
        let lines = TVStatusLine.lines(
            discord: nil,
            film: try decode(#"{"title": ""}"#),
            record: nil,
            trophy: nil,
            weather: try decode(#"{"condition": "fog"}"#)
        )

        XCTAssertTrue(lines.isEmpty)
    }

    private func decode<T: Decodable>(_ json: String) throws -> T {
        try JSONDecoder().decode(T.self, from: Data(json.utf8))
    }
}

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

    func testTheNewSourcesReadAsOneLineEach() throws {
        let lines = TVStatusLine.lines(
            discord: nil,
            film: nil,
            record: nil,
            scrobbles: try decode(#"{"tracks": [{"title": "angel", "artist": "massive attack", "nowPlaying": true}]}"#),
            steam: try decode(#"{"profile": {}, "games": [{"appId": 10, "name": "counter-strike", "minutesTwoWeeks": 120}]}"#),
            youtube: try decode(#"{"channel": {"title": "httpjpg", "subscriberCount": 812}, "videos": [{"title": "studio tour"}]}"#),
            github: try decode(#"{"profile": {}, "activity": [{"verb": "merged", "repo": "dmnktoe/httpjpg", "detail": "#42"}]}"#),
            reddit: RedditKarma(username: "dmnktoe", karma: 812),
            trophy: nil,
            weather: nil
        )

        XCTAssertEqual(lines.map(\.text), [
            "last.fm: angel · massive attack · ▶",
            "steam: counter-strike · 2h / 2w",
            "youtube: (812) · studio tour",
            "github: merged dmnktoe/httpjpg #42",
            "reddit: u/dmnktoe · 812 karma",
        ])
    }

    func testLinesRunLiveFirstThenNewest() throws {
        let lines = TVStatusLine.lines(
            discord: try decode(#"{"status": "offline"}"#),
            film: try decode(#"{"title": "stalker", "watchedDate": "2026-11-05"}"#),
            record: try decode(#"{"title": "saw", "artist": "aphex twin", "addedAt": "2026-11-20T10:00:00Z"}"#),
            scrobbles: try decode(#"{"tracks": [{"title": "angel", "artist": "massive attack", "nowPlaying": true}]}"#),
            trophy: nil,
            weather: nil
        )

        XCTAssertEqual(lines.map(\.id), ["lastfm", "discogs", "letterboxd", "discord"])
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

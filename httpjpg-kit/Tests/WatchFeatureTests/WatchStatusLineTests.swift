import StoryblokCore
import XCTest

@testable import WatchFeature

final class WatchStatusLineTests: XCTestCase {
    func testEverySourceBecomesOneLineInTheWebFooterOrder() throws {
        let lines = WatchStatusLine.lines(from: WatchStatusLine.Sources(
            discord: try decode(#"{"status": "online", "activity": "Xcode"}"#),
            film: try decode(#"{"title": "Babystar", "year": "2025", "poster": "data:image/png;base64,cG9zdGVy"}"#),
            record: try decode(#"{"title": "Endtroducing.....", "artist": "DJ Shadow", "year": "1996"}"#),
            scrobbles: try decode(#"{"tracks": [{"title": "Angel", "artist": "Massive Attack", "nowPlaying": true}]}"#),
            steam: try decode(#"{"profile": {}, "games": [{"appId": 10, "name": "Counter-Strike", "minutesTwoWeeks": 45}]}"#),
            youtube: try decode(#"{"channel": {"title": "httpjpg", "subscriberCount": 1230}, "videos": [{"title": "Studio tour"}]}"#),
            github: try decode(#"{"profile": {}, "activity": [{"verb": "pushed to", "repo": "dmnktoe/httpjpg", "detail": "main"}]}"#),
            reddit: RedditKarma(username: "dmnktoe", karma: 12345),
            timeline: try decode(#"{"profile": {"username": "dmnktoe", "followerCount": 812}, "posts": [{"text": "shipping"}]}"#),
            trophy: try decode(#"{"name": "Pathfinder", "game": "TSW7"}"#),
            schalke: try decode(#"{"standing": {"position": 17, "trend": "same"}}"#),
            weather: try decode(#"{"temperature": 0.9, "emoji": "☁️", "condition": "overcast"}"#)
        ))

        XCTAssertEqual(lines.map(\.id), [
            "discord", "letterboxd", "discogs", "lastfm", "steam", "youtube", "github", "reddit", "x", "psn", "schalke",
            "weather",
        ])
        XCTAssertEqual(lines[1].image, Data("poster".utf8))
        XCTAssertEqual(lines[3].detail, "Massive Attack ▶")
        XCTAssertEqual(lines[4].detail, "45m / 2w")
        XCTAssertEqual(lines[5].detail, "(1.2K)")
        XCTAssertEqual(lines[6].text, "dmnktoe/httpjpg")
        XCTAssertEqual(lines[6].detail, "pushed to main")
        XCTAssertEqual(lines[7].detail, "12.3K karma")
        XCTAssertEqual(lines[11].text, "☁️ 1°")
    }

    func testSilentSourcesAreLeftOut() throws {
        let lines = WatchStatusLine.lines(from: WatchStatusLine.Sources(
            film: try decode(#"{"title": ""}"#),
            scrobbles: try decode(#"{"tracks": []}"#),
            steam: try decode(#"{"profile": {}, "games": []}"#),
            youtube: try decode(#"{"channel": {"title": "httpjpg"}, "videos": []}"#),
            github: try decode(#"{"profile": {}, "activity": []}"#),
            schalke: try decode(#"{"fixture": null, "standing": null}"#),
            weather: try decode(#"{"condition": "fog"}"#)
        ))

        XCTAssertTrue(lines.isEmpty)
    }

    private func decode<T: Decodable>(_ json: String) throws -> T {
        try JSONDecoder().decode(T.self, from: Data(json.utf8))
    }
}

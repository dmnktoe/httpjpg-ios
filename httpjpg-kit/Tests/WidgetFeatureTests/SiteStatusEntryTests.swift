import StoryblokContent
import XCTest

@testable import WidgetFeature

final class SiteStatusEntryTests: XCTestCase {
    func testEveryReportedSourceBecomesALine() throws {
        let entry = SiteStatusEntry(
            date: .now,
            discord: try decode(#"{"status": "idle", "activity": "Xcode"}"#),
            film: try decode(#"{"title": "Chungking Express", "year": "1994", "rating": 4.5, "liked": true}"#),
            record: try decode(#"{"title": "Endtroducing.....", "artist": "DJ Shadow", "year": "1996"}"#),
            timeline: try decode(
                #"{"profile": {"username": "dmnktoe", "followerCount": 1234}, "posts": [{"text": "shipping"}]}"#
            ),
            trophy: try decode(#"{"name": "Nachtfahrt", "game": "Death Stranding", "type": "gold"}"#),
            weather: try decode(#"{"temperature": 18.4, "emoji": "🌤", "condition": "bewölkt"}"#)
        )

        XCTAssertEqual(
            entry.lines.map(\.id),
            ["discord", "letterboxd", "discogs", "x", "psn", "weather"]
        )
    }

    func testMissingSourcesDropOutInsteadOfShowingBlanks() throws {
        let entry = SiteStatusEntry(
            date: .now,
            discord: try decode(#"{"status": "offline"}"#),
            film: try decode(#"{"title": ""}"#),
            record: try decode(#"{"title": "", "artist": "DJ Shadow"}"#),
            timeline: try decode(#"{"profile": {"username": "dmnktoe"}, "posts": []}"#),
            trophy: try decode(#"{"name": "", "game": ""}"#),
            weather: try decode(#"{"emoji": "🌧"}"#)
        )

        XCTAssertEqual(entry.lines.map(\.id), ["discord"])
    }

    func testAFilmCarriesItsYearRatingAndHeart() throws {
        let film: LetterboxdFilm = try decode(
            #"{"title": "Chungking Express", "year": "1994", "rating": 4.5, "liked": true}"#
        )

        let line = try XCTUnwrap(SiteStatusLine(film: film))

        XCTAssertEqual(line.text, "Chungking Express")
        XCTAssertEqual(line.detail, "1994 ★★★★½ ♥")
    }

    func testARecordReadsAsArtistThenTitle() throws {
        let record: DiscogsRelease = try decode(
            #"{"title": "Endtroducing.....", "artist": "DJ Shadow", "year": "1996", "format": "Vinyl LP"}"#
        )

        let line = try XCTUnwrap(SiteStatusLine(record: record))

        XCTAssertEqual(line.text, "DJ Shadow — Endtroducing.....")
        XCTAssertEqual(line.detail, "1996 Vinyl LP")
    }

    func testAPostLeadsWithTheCompactedFollowerCount() throws {
        let timeline: XTimeline = try decode(
            #"{"profile": {"username": "dmnktoe", "followerCount": 1234}, "posts": [{"text": "shipping"}]}"#
        )
        let post = try XCTUnwrap(timeline.latestPost)

        let line = try XCTUnwrap(SiteStatusLine(profile: timeline.profile, post: post))

        XCTAssertEqual(line.text, "(1.2K)")
        XCTAssertEqual(line.detail, "shipping")
    }

    func testAPostWithoutAFollowerCountFallsBackToTheHandle() throws {
        let timeline: XTimeline = try decode(
            #"{"profile": {"username": "dmnktoe"}, "posts": [{"text": "shipping"}]}"#
        )
        let post = try XCTUnwrap(timeline.latestPost)

        let line = try XCTUnwrap(SiteStatusLine(profile: timeline.profile, post: post))

        XCTAssertEqual(line.text, "@dmnktoe")
    }

    func testTemperatureIsRoundedToWholeDegrees() throws {
        let weather: WeatherNow = try decode(#"{"temperature": 18.6, "condition": "bewölkt"}"#)

        let line = try XCTUnwrap(SiteStatusLine(weather: weather))

        XCTAssertEqual(line.text, "19°")
        XCTAssertEqual(line.detail, "bewölkt")
    }

    func testAnUnknownTrophyTypeStillGetsABadge() throws {
        let trophy: PsnTrophy = try decode(#"{"name": "Nachtfahrt", "game": "Death Stranding"}"#)

        let line = try XCTUnwrap(SiteStatusLine(trophy: trophy))

        XCTAssertEqual(line.badge, "🎮")
    }

    private func decode<T: Decodable>(_ json: String) throws -> T {
        try JSONDecoder().decode(T.self, from: Data(json.utf8))
    }
}

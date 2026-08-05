import StoryblokContent
import XCTest

@testable import WidgetFeature

final class SiteStatusEntryTests: XCTestCase {
    func testEveryReportedSourceBecomesALine() throws {
        let entry = SiteStatusEntry(
            date: .now,
            discord: try decode(#"{"status": "idle", "activity": "Xcode"}"#),
            film: try decode(#"{"title": "Chungking Express", "year": "1994", "rating": 4.5, "liked": true}"#),
            trophy: try decode(#"{"name": "Nachtfahrt", "game": "Death Stranding", "type": "gold"}"#),
            weather: try decode(#"{"temperature": 18.4, "emoji": "🌤", "condition": "bewölkt"}"#)
        )

        XCTAssertEqual(entry.lines.map(\.id), ["discord", "letterboxd", "psn", "weather"])
    }

    func testMissingSourcesDropOutInsteadOfShowingBlanks() throws {
        let entry = SiteStatusEntry(
            date: .now,
            discord: try decode(#"{"status": "offline"}"#),
            film: try decode(#"{"title": ""}"#),
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

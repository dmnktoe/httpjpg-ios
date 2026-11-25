import StoryblokCore
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
            schalke: try decode(#"{"standing": {"position": 17, "trend": "same"}}"#),
            weather: try decode(#"{"temperature": 18.4, "emoji": "🌤", "condition": "bewölkt"}"#)
        )

        XCTAssertEqual(
            entry.lines.map(\.id),
            ["discord", "letterboxd", "discogs", "x", "psn", "schalke", "weather"]
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
            schalke: try decode(#"{"fixture": null, "standing": null}"#),
            weather: try decode(#"{"emoji": "🌧"}"#)
        )

        XCTAssertEqual(entry.lines.map(\.id), ["discord"])
    }

    func testLinesRunNewestFirstWithLivePresenceOnTopAndUndatedLast() throws {
        let entry = SiteStatusEntry(
            date: .now,
            discord: try decode(#"{"status": "online", "activity": "Xcode"}"#),
            film: try decode(#"{"title": "Babystar", "watchedDate": "2026-11-05"}"#),
            record: try decode(
                #"{"title": "All I Want", "artist": "2 The Bone", "addedAt": "2020-07-08T21:36:57-07:00"}"#
            ),
            trophy: try decode(#"{"name": "Pathfinder", "game": "TSW7", "earnedAt": "2026-11-14T22:42:29Z"}"#),
            schalke: try decode(
                #"{"fixture": {"home": "Hoffenheim", "away": "S04", "playedAt": "2026-11-08T18:30:00Z"}}"#
            ),
            weather: try decode(#"{"temperature": 0.9, "emoji": "☁️"}"#)
        )

        XCTAssertEqual(
            entry.lines.map(\.id),
            ["discord", "psn", "schalke", "letterboxd", "discogs", "weather"]
        )
    }

    func testAnOfflinePresenceSinksBelowTheDatedLines() throws {
        let entry = SiteStatusEntry(
            date: .now,
            discord: try decode(#"{"status": "offline"}"#),
            film: try decode(#"{"title": "Babystar", "watchedDate": "2026-11-05"}"#),
            weather: try decode(#"{"temperature": 0.9}"#)
        )

        XCTAssertEqual(entry.lines.map(\.id), ["letterboxd", "discord", "weather"])
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

    func testAResultIsTintedByOutcomeAndCarriesThePlace() throws {
        let status: SchalkeStatus = try decode(
            #"""
            {"fixture": {"home": "Hoffenheim", "away": "S04", "homeGoals": 2, "awayGoals": 1, "outcome": "loss",
                         "homeCrest": "data:image/png;base64,aG9tZQ==", "awayCrest": "data:image/png;base64,YXdheQ=="},
             "standing": {"position": 17, "previousPosition": 16, "trend": "down"}}
            """#
        )

        let line = try XCTUnwrap(SiteStatusLine(schalke: status))

        XCTAssertEqual(line.text, "Hoffenheim 2:1 S04")
        XCTAssertEqual(line.detail, "↓ 17.")
        XCTAssertEqual(line.leadingImage, Data("home".utf8))
        XCTAssertEqual(line.trailingImage, Data("away".utf8))
        XCTAssertNotNil(line.tint)
    }

    func testTheNextMatchCarriesItsKickoffAndThePlace() throws {
        let status: SchalkeStatus = try decode(
            #"""
            {"upcoming": {"home": "S04", "away": "Stuttgart", "homeCrest": "data:image/png;base64,aG9tZQ==",
                          "kickoff": "2026-11-21T17:30:00Z"},
             "standing": {"position": 17, "trend": "same"}}
            """#
        )
        let now = try XCTUnwrap(StoryblokDate.parse("2026-11-17T10:00:00Z"))

        let line = try XCTUnwrap(SiteStatusLine(schalke: status, now: now))

        XCTAssertEqual(line.text, "S04 – Stuttgart")
        XCTAssertEqual(line.detail, "Sat 18:30 · 17.")
        XCTAssertEqual(line.leadingImage, Data("home".utf8))
        XCTAssertNil(line.date, "a match still to come does not sort as the newest line")
    }

    func testThePlaceStandsAloneWithoutARecentFixture() throws {
        let status: SchalkeStatus = try decode(#"{"standing": {"position": 4, "trend": "up"}}"#)

        let line = try XCTUnwrap(SiteStatusLine(schalke: status))

        XCTAssertEqual(line.text, "↑ 4.")
        XCTAssertNil(line.leadingImage)
    }

    func testTheNewSourcesFollowTheWebFooterOrder() throws {
        let entry = SiteStatusEntry(
            date: .now,
            record: try decode(#"{"title": "Endtroducing.....", "artist": "DJ Shadow"}"#),
            scrobbles: try decode(#"{"tracks": [{"title": "Teardrop", "artist": "Massive Attack"}]}"#),
            steam: try decode(#"{"profile": {}, "games": [{"appId": 10, "name": "Counter-Strike"}]}"#),
            youtube: try decode(#"{"channel": {"title": "httpjpg"}, "videos": [{"title": "Studio tour"}]}"#),
            github: try decode(#"{"profile": {}, "activity": [{"verb": "starred", "repo": "x/y"}]}"#)
        )

        XCTAssertEqual(entry.lines.map(\.id), ["discogs", "lastfm", "steam", "youtube", "github"])
    }

    func testATrackPlayingNowSortsAsTheNewestLine() throws {
        let now = try XCTUnwrap(StoryblokDate.parse("2026-11-25T10:00:00Z"))
        let entry = SiteStatusEntry(
            date: now,
            film: try decode(#"{"title": "Babystar", "watchedDate": "2026-11-24"}"#),
            scrobbles: try decode(
                #"{"tracks": [{"title": "Angel", "artist": "Massive Attack", "nowPlaying": true, "loved": true}]}"#
            )
        )

        let line = try XCTUnwrap(entry.lines.first)
        XCTAssertEqual(line.id, "lastfm")
        XCTAssertEqual(line.text, "Angel")
        XCTAssertEqual(line.detail, "Massive Attack ▶ ♥")
        XCTAssertEqual(line.date, now)
    }

    func testTheRunningSteamGameIsMarkedAndCarriesItsPlaytime() throws {
        let steam: SteamStatus = try decode(
            #"""
            {"profile": {"inGame": {"appId": 1245620, "name": "ELDEN RING"}},
             "games": [{"appId": 1245620, "name": "ELDEN RING", "minutesTwoWeeks": 845,
                        "icon": "data:image/png;base64,aWNvbg=="}]}
            """#
        )

        let line = try XCTUnwrap(SiteStatusLine(steam: steam))

        XCTAssertEqual(line.text, "ELDEN RING ▶")
        XCTAssertEqual(line.detail, "14h / 2w")
        XCTAssertEqual(line.leadingImage, Data("icon".utf8))
    }

    func testAnUploadCarriesTheSubscriberCountAndAGithubEventReadsAsASentence() throws {
        let youtube: YoutubeStatus = try decode(
            #"{"channel": {"title": "httpjpg", "subscriberCount": 1230}, "videos": [{"title": "Studio tour"}]}"#
        )
        let github: GithubStatus = try decode(
            #"{"profile": {}, "activity": [{"verb": "pushed to", "repo": "dmnktoe/httpjpg", "detail": "main"}]}"#
        )

        let upload = try XCTUnwrap(SiteStatusLine(youtube: youtube))
        let push = try XCTUnwrap(SiteStatusLine(github: github))

        XCTAssertEqual(upload.text, "Studio tour")
        XCTAssertEqual(upload.detail, "(1.2K)")
        XCTAssertEqual(push.text, "pushed to dmnktoe/httpjpg")
        XCTAssertEqual(push.detail, "main")
    }

    func testFooterLinesShowTheSitesPixelArt() throws {
        let film: LetterboxdFilm = try decode(#"{"title": "Babystar", "poster": "data:image/png;base64,cG9zdGVy"}"#)
        let trophy: PsnTrophy = try decode(#"{"name": "Pathfinder", "image": "data:image/png;base64,dA=="}"#)

        XCTAssertEqual(SiteStatusLine(film: film)?.leadingImage, Data("poster".utf8))
        XCTAssertEqual(SiteStatusLine(trophy: trophy)?.leadingImage, Data("t".utf8))
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

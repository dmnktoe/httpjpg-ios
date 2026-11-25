import StoryblokCore
import SwiftUI
import Tokens

struct SiteStatusLine: Identifiable {
    let id: String
    let label: String
    let badge: String

    let leadingImage: Data?
    let trailingImage: Data?
    let text: String

    let detail: String?

    let tint: Color?

    let date: Date?

    init(
        id: String,
        label: String,
        badge: String,
        leadingImage: Data? = nil,
        trailingImage: Data? = nil,
        text: String,
        detail: String? = nil,
        tint: Color? = nil,
        date: Date? = nil
    ) {
        self.id = id
        self.label = label
        self.badge = badge
        self.leadingImage = leadingImage
        self.trailingImage = trailingImage
        self.text = text
        self.detail = detail
        self.tint = tint
        self.date = date
    }

    init(discord presence: DiscordPresence) {
        self.init(
            id: "discord",
            label: "discord:",
            badge: Self.badge(for: presence.status),
            text: presence.status.rawValue,
            detail: presence.activity,
            tint: Self.tint(for: presence.status)
        )
    }

    init?(film: LetterboxdFilm) {
        guard !film.title.isEmpty else { return nil }
        let detail = [film.year, film.stars, film.liked ? "♥" : nil]
            .compactMap { $0 }
            .joined(separator: " ")

        self.init(
            id: "letterboxd",
            label: "letterboxd:",
            badge: "🎞",
            leadingImage: film.poster,
            text: film.title,
            detail: detail.isEmpty ? nil : detail,
            date: film.watchedDate
        )
    }

    init?(record: DiscogsRelease) {
        guard !record.title.isEmpty else { return nil }
        let detail = [record.year, record.format]
            .compactMap { $0 }
            .joined(separator: " ")

        self.init(
            id: "discogs",
            label: "discogs:",
            badge: "💿",
            leadingImage: record.thumb,
            text: record.credit,
            detail: detail.isEmpty ? nil : detail,
            date: record.addedAt
        )
    }

    init?(profile: XProfile, post: XPost) {
        guard !post.text.isEmpty else { return nil }
        self.init(
            id: "x",
            label: "x:",
            badge: "𝕏",
            leadingImage: profile.avatar,
            text: profile.compactFollowerCount.map { "(\($0))" } ?? profile.handle,
            detail: post.text
        )
    }

    init?(trophy: PsnTrophy) {
        guard !trophy.name.isEmpty else { return nil }
        self.init(
            id: "psn",
            label: "psn:",
            badge: trophy.badge,
            leadingImage: trophy.image,
            text: trophy.name,
            detail: trophy.game.isEmpty ? nil : trophy.game,
            date: trophy.earnedAt
        )
    }

    init?(scrobbles: LastfmScrobbles, now: Date = .now) {
        guard let track = scrobbles.latest else { return nil }
        let marks = [track.isNowPlaying ? "▶" : nil, track.isLoved ? "♥" : nil].compactMap { $0 }
        self.init(
            id: "lastfm",
            label: "last.fm:",
            badge: "♫",
            leadingImage: track.image,
            text: track.title,
            detail: ([track.artist] + marks).joined(separator: " "),
            // A track still playing has no scrobble time yet; it is the freshest line there is.
            date: track.scrobbledAt ?? (track.isNowPlaying ? now : nil)
        )
    }

    init?(steam: SteamStatus, now: Date = .now) {
        guard let game = steam.featured else { return nil }
        self.init(
            id: "steam",
            label: "steam:",
            badge: "🎮",
            leadingImage: game.icon,
            text: steam.isPlaying ? "\(game.name) ▶" : game.name,
            detail: game.recentPlaytime,
            date: steam.isPlaying ? now : nil
        )
    }

    init?(youtube: YoutubeStatus) {
        guard let video = youtube.latestVideo else { return nil }
        self.init(
            id: "youtube",
            label: "youtube:",
            badge: "▶︎",
            leadingImage: youtube.channel.avatar,
            text: video.title,
            detail: youtube.channel.compactSubscriberCount.map { "(\($0))" },
            date: video.publishedAt
        )
    }

    init?(github: GithubStatus) {
        guard let activity = github.latest else { return nil }
        self.init(
            id: "github",
            label: "github:",
            badge: "⌥",
            leadingImage: github.avatar,
            text: "\(activity.verb) \(activity.repo)",
            detail: activity.detail,
            date: activity.createdAt
        )
    }

    init(reddit: RedditKarma) {
        self.init(
            id: "reddit",
            label: "reddit:",
            badge: "👽",
            text: reddit.handle,
            detail: reddit.compactKarma
        )
    }

    init?(schalke status: SchalkeStatus, now: Date = .now) {
        let place = status.standing.map { standing -> String in
            switch standing.trend {
            case .up: return "↑ \(standing.position)."
            case .down: return "↓ \(standing.position)."
            case .same: return "\(standing.position)."
            }
        }

        if let fixture = status.fixture {
            self.init(
                id: "schalke",
                label: "s04:",
                badge: "⚽",
                leadingImage: fixture.homeCrest,
                trailingImage: fixture.awayCrest,
                text: fixture.score,
                detail: place,
                tint: Self.tint(for: fixture.outcome),
                date: fixture.playedAt
            )
        } else if let upcoming = status.upcoming {
            let detail = [upcoming.kickoffLabel(now: now), place]
                .compactMap { $0 }
                .joined(separator: " · ")
            self.init(
                id: "schalke",
                label: "s04:",
                badge: "⚽",
                leadingImage: upcoming.homeCrest,
                trailingImage: upcoming.awayCrest,
                text: upcoming.pairing,
                detail: detail.isEmpty ? nil : detail
            )
        } else if let place {
            self.init(id: "schalke", label: "s04:", badge: "⚽", text: place)
        } else {
            return nil
        }
    }

    init?(weather: WeatherNow) {
        guard let temperature = weather.temperature else { return nil }
        self.init(
            id: "weather",
            label: "weather:",
            badge: weather.emoji ?? "☁️",
            text: "\(Int(temperature.rounded()))°",
            detail: weather.condition
        )
    }

    private static func badge(for status: DiscordPresence.Status) -> String {
        switch status {
        case .online: return "🟢"
        case .idle: return "🟡"
        case .dnd: return "🔴"
        case .offline: return "⚫"
        }
    }

    private static func tint(for outcome: SchalkeFixture.Outcome) -> Color {
        switch outcome {
        case .win: return Palette.success.s500
        case .draw: return Palette.neutral.s500
        case .loss: return Palette.danger.s500
        }
    }

    private static func tint(for status: DiscordPresence.Status) -> Color {
        switch status {
        case .online: return Palette.success.s500
        case .idle: return Palette.warning.s500
        case .dnd: return Palette.danger.s500
        case .offline: return Palette.neutral.s500
        }
    }
}

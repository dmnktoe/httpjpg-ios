import DesignSystem
import StoryblokContent
import SwiftUI

/// One footer status row, flattened for the widget: the site renders these as live
/// components, a widget only ever gets the snapshot.
struct SiteStatusLine: Identifiable {
    let id: String
    let label: String
    let badge: String
    let text: String

    /// Trails the text at reduced opacity — the activity, the rating, the game.
    let detail: String?

    let tint: Color?

    init(
        id: String,
        label: String,
        badge: String,
        text: String,
        detail: String? = nil,
        tint: Color? = nil
    ) {
        self.id = id
        self.label = label
        self.badge = badge
        self.text = text
        self.detail = detail
        self.tint = tint
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
            text: film.title,
            detail: detail.isEmpty ? nil : detail
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
            text: record.credit,
            detail: detail.isEmpty ? nil : detail
        )
    }

    /// No avatar — a widget refresh would have to fetch it. The follower count
    /// leads instead, so the post is what truncates.
    init?(profile: XProfile, post: XPost) {
        guard !post.text.isEmpty else { return nil }
        self.init(
            id: "x",
            label: "x:",
            badge: "𝕏",
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
            text: trophy.name,
            detail: trophy.game.isEmpty ? nil : trophy.game
        )
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

    private static func tint(for status: DiscordPresence.Status) -> Color {
        switch status {
        case .online: return Palette.success.s500
        case .idle: return Palette.warning.s500
        case .dnd: return Palette.danger.s500
        case .offline: return Palette.neutral.s500
        }
    }
}

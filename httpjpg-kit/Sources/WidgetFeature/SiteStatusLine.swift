import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

struct SiteStatusLine: Identifiable {
    let id: String
    let label: String
    let badge: String

    /// Drawn in place of the badge wherever shapes can render; the badge stays
    /// for the inline accessory, which is text only.
    let glyph: PixelGlyph.Kind?
    let text: String

    let detail: String?

    let tint: Color?

    init(
        id: String,
        label: String,
        badge: String,
        glyph: PixelGlyph.Kind? = nil,
        text: String,
        detail: String? = nil,
        tint: Color? = nil
    ) {
        self.id = id
        self.label = label
        self.badge = badge
        self.glyph = glyph
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

    init?(schalke status: SchalkeStatus) {
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
                glyph: .dot,
                text: fixture.score,
                detail: place,
                tint: Self.tint(for: fixture.outcome)
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

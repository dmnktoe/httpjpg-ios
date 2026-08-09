import Combine
import DesignSystem
import StoryblokContent
import SwiftUI

struct FooterWidgets: View {
    let model: FooterWidgetsModel

    var body: some View {
        VStack(spacing: Spacing.s1) {
            if model.isLoaded {
                if let discord = model.discord {
                    DiscordLine(presence: discord)
                }
                if let film = model.film {
                    LetterboxdLine(film: film)
                }
                if let record = model.record {
                    DiscogsLine(record: record)
                }
                if let timeline = model.timeline, let post = timeline.latestPost {
                    XLine(profile: timeline.profile, post: post)
                }
                if let trophy = model.trophy {
                    TrophyLine(trophy: trophy)
                }
            } else {
                ForEach(pendingLabels, id: \.self) { placeholderLine(label: $0) }
            }
            ClockLine(weather: model.weather)
        }
        .frame(maxWidth: .infinity)
        .animation(Motion.stateChange, value: model.isLoaded)
    }

    private var pendingLabels: [String] {
        let flags = model.flags
        return [
            flags.isDiscordEnabled ? "discord:" : nil,
            flags.isLetterboxdEnabled ? "letterboxd:" : nil,
            flags.isDiscogsEnabled ? "discogs:" : nil,
            flags.isXEnabled ? "x:" : nil,
            flags.isPsnTrophyEnabled ? "psn:" : nil,
        ].compactMap { $0 }
    }

    private func placeholderLine(label: String) -> some View {
        FooterStatusLine(label: label) {
            Text("loading …").opacity(Opacities.subtle)
        }
    }
}

private struct DiscordLine: View {
    let presence: DiscordPresence

    var body: some View {
        FooterStatusLine(label: "discord:") {
            Text(badge)
            Text(presence.status.rawValue)
                .foregroundStyle(color)
            if let activity = presence.activity {
                Text("·").opacity(Opacities.subtle)
                Text(activity)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .opacity(Opacities.muted)
            }
        }
    }

    private var badge: String {
        switch presence.status {
        case .online: return "🟢"
        case .idle: return "🟡"
        case .dnd: return "🔴"
        case .offline: return "⚫"
        }
    }

    private var color: Color {
        switch presence.status {
        case .online: return Palette.success.s500
        case .idle: return Palette.warning.s500
        case .dnd: return Palette.danger.s500
        case .offline: return Palette.neutral.s500
        }
    }
}

private struct LetterboxdLine: View {
    let film: LetterboxdFilm

    var body: some View {
        FooterStatusLine(label: "letterboxd:") {
            Text("🎞")
            Text(film.title)
                .lineLimit(1)
                .truncationMode(.tail)
            if let year = film.year {
                Text(year).opacity(Opacities.subtle)
            }
            if let stars = film.stars {
                Text(stars).opacity(Opacities.muted)
            }
            if film.liked {
                Text("♥")
            }
        }
    }
}

private struct DiscogsLine: View {
    let record: DiscogsRelease

    var body: some View {
        FooterStatusLine(label: "discogs:") {
            if let thumb = record.thumb.flatMap(URL.init(string:)) {
                FooterThumb(url: thumb, clip: .rect(cornerRadius: 2))
            } else {
                Text("💿")
            }
            Text(record.credit)
                .lineLimit(1)
                .truncationMode(.tail)
            if let year = record.year {
                Text(year).opacity(Opacities.subtle)
            }
            if let format = record.format {
                Text("·").opacity(Opacities.subtle)
                Text(format)
                    .lineLimit(1)
                    .opacity(Opacities.muted)
            }
        }
    }
}

private struct XLine: View {
    let profile: XProfile
    let post: XPost

    var body: some View {
        FooterStatusLine(label: "x:") {
            // The handle rides in the accessibility label rather than on the
            // row: the site keeps it in a tooltip for the same reason, and a
            // row this narrow truncates the post text first.
            if let avatar = profile.avatar.flatMap(URL.init(string:)) {
                FooterThumb(url: avatar, clip: .circle)
                    .accessibilityLabel(profile.handle)
            } else {
                Text("𝕏").accessibilityLabel(profile.handle)
            }
            if let followers = profile.compactFollowerCount {
                Text("(\(followers))").opacity(Opacities.subtle)
            }
            Text("·").opacity(Opacities.subtle)
            Text(post.text)
                .lineLimit(1)
                .truncationMode(.tail)
            if post.isQuote {
                Text("❝").opacity(Opacities.subtle)
            }
            if post.hasMedia {
                Text("▣").opacity(Opacities.subtle)
            }
        }
    }
}

/// The image slot in a status row. `RemoteImage` is built for cards and falls
/// back to a glyph that is illegible at 14pt, so a row loads its own thumbnail
/// and simply stays empty on a miss.
private struct FooterThumb<Clip: Shape>: View {
    let url: URL
    let clip: Clip

    var body: some View {
        AsyncImage(url: url) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.clear
            }
        }
        .frame(width: Typography.Size.md, height: Typography.Size.md)
        .clipShape(clip)
    }
}

private struct TrophyLine: View {
    let trophy: PsnTrophy

    var body: some View {
        FooterStatusLine(label: "psn:") {
            Text(trophy.badge)
            Text(trophy.name)
                .lineLimit(1)
                .truncationMode(.tail)
            Text("·").opacity(Opacities.subtle)
            Text(trophy.game)
                .lineLimit(1)
                .truncationMode(.tail)
                .opacity(Opacities.muted)
        }
    }
}

private struct ClockLine: View {
    let weather: WeatherNow?

    @State private var now = Date()

    /// The clock reads as "what time it is here", so it stays pinned to the
    /// site's home zone for every reader — the same contract the website holds.
    private static let homeTimeZone = TimeZone(identifier: "Europe/Berlin") ?? .gmt

    private static let clock: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.timeZone = homeTimeZone
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    var body: some View {
        FooterStatusLine(label: nil) {
            Text(Self.clock.string(from: now))
            Text(offset).opacity(Opacities.subtle)
            if let weather, let emoji = weather.emoji {
                Text("·").opacity(Opacities.subtle)
                Text(emoji)
                if let temperature = weather.temperature {
                    Text("\(Int(temperature.rounded()))°")
                }
                if let condition = weather.condition, !condition.isEmpty {
                    Text(condition)
                        .lineLimit(1)
                        .opacity(Opacities.muted)
                }
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { now = $0 }
    }

    private var offset: String {
        let seconds = Self.homeTimeZone.secondsFromGMT(for: now)
        if seconds == 0 { return "UTC" }
        let hours = seconds / 3600
        let minutes = abs(seconds % 3600) / 60
        let sign = seconds < 0 ? "-" : "+"
        return minutes == 0
            ? "UTC\(sign)\(abs(hours))"
            : String(format: "UTC%@%d:%02d", sign, abs(hours), minutes)
    }
}

private struct FooterStatusLine<Content: View>: View {
    let label: String?
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: Spacing.s1) {
            if let label {
                Text(label).opacity(Opacities.subtle)
            }
            content
        }
        .font(Typography.mono(Typography.Size.xs))

        .lineLimit(1)
        .opacity(0.8)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, PageLayout.gutter)
    }
}

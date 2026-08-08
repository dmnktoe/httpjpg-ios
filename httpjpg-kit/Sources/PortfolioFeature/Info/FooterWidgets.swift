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
                if let trophy = model.trophy {
                    TrophyLine(trophy: trophy)
                }
            } else {
                placeholderLine(label: "discord:")
                placeholderLine(label: "letterboxd:")
                placeholderLine(label: "psn:")
            }
            ClockLine(weather: model.weather)
        }
        .frame(maxWidth: .infinity)
        .animation(Motion.stateChange, value: model.isLoaded)
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

    private static let clock: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
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
        let seconds = TimeZone.current.secondsFromGMT(for: now)
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

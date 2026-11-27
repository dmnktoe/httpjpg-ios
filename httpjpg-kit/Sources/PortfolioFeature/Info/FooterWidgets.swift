import Combine
import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens
import UIKit

struct FooterWidgets: View {
    let model: FooterWidgetsModel
    var onShowMore: (() -> Void)?

    private static let collapsedLineCount = 3

    var body: some View {
        VStack(spacing: Spacing.s1) {
            if model.isLoaded {
                ForEach(folded(sortedLines)) { line in
                    row(line)
                }
                moreButton(lineCount: sortedLines.count)
            } else {
                ForEach(folded(pendingLabels), id: \.self) { placeholderLine(label: $0) }
                moreButton(lineCount: pendingLabels.count)
            }
            ClockLine(weather: model.weather)
        }
        .frame(maxWidth: .infinity)
        .animation(Motion.stateChange, value: model.isLoaded)
    }

    private var sortedLines: [FooterLine] {
        StatusOrder.sorted(lines, isLive: \.isLive, date: \.date)
    }

    private func folded<Item>(_ items: [Item]) -> [Item] {
        onShowMore == nil ? items : Array(items.prefix(Self.collapsedLineCount))
    }

    @ViewBuilder
    private func moreButton(lineCount total: Int) -> some View {
        let hidden = total - Self.collapsedLineCount
        if let onShowMore, hidden > 0 {
            Button(action: onShowMore) {
                Text("[ + \(hidden) more ]")
                    .font(Typography.mono(Typography.Size.xs))
                    .opacity(Opacities.subtle)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, PageLayout.gutter)
            .accessibilityLabel("Show all \(total) status lines")
        }
    }

    private var lines: [FooterLine] {
        var lines: [FooterLine] = []
        if let discord = model.discord { lines.append(.discord(discord)) }
        if let film = model.film { lines.append(.film(film)) }
        if let record = model.record { lines.append(.record(record)) }
        if let scrobbles = model.scrobbles, let track = scrobbles.latest {
            lines.append(.scrobble(track, total: scrobbles.compactTotal))
        }
        if let steam = model.steam, let line = steam.line {
            lines.append(.steam(steam, line))
        }
        if let youtube = model.youtube, let video = youtube.latestVideo {
            lines.append(.youtube(youtube.channel, video))
        }
        if let github = model.github, let activity = github.latest {
            lines.append(.github(github.avatar, activity))
        }
        if let reddit = model.flags.reddit { lines.append(.reddit(reddit)) }
        if let timeline = model.timeline, let post = timeline.latestPost {
            lines.append(.x(timeline.profile, post))
        }
        if let trophy = model.trophy { lines.append(.trophy(trophy)) }
        if let schalke = model.schalke, !schalke.isEmpty { lines.append(.schalke(schalke)) }
        return lines
    }

    @ViewBuilder
    private func row(_ line: FooterLine) -> some View {
        switch line {
        case .discord(let presence): DiscordLine(presence: presence)
        case .film(let film): LetterboxdLine(film: film)
        case .record(let record): DiscogsLine(record: record)
        case .scrobble(let track, let total): LastfmLine(track: track, total: total)
        case .steam(let steam, let line): SteamLine(steam: steam, line: line)
        case .youtube(let channel, let video): YoutubeLine(channel: channel, video: video)
        case .github(let avatar, let activity): GithubLine(avatar: avatar, activity: activity)
        case .reddit(let reddit): RedditLine(reddit: reddit)
        case .x(let profile, let post): XLine(profile: profile, post: post)
        case .trophy(let trophy): TrophyLine(trophy: trophy)
        case .schalke(let status): SchalkeLine(status: status)
        }
    }

    private var pendingLabels: [String] {
        let flags = model.flags
        return [
            flags.isDiscordEnabled ? "discord:" : nil,
            flags.isLetterboxdEnabled ? "letterboxd:" : nil,
            flags.isDiscogsEnabled ? "discogs:" : nil,
            flags.isLastfmEnabled ? "last.fm:" : nil,
            flags.isSteamEnabled ? "steam:" : nil,
            flags.isYoutubeEnabled ? "youtube:" : nil,
            flags.isGithubEnabled ? "github:" : nil,
            flags.reddit != nil ? "reddit:" : nil,
            flags.isXEnabled ? "x:" : nil,
            flags.isPsnTrophyEnabled ? "psn:" : nil,
            flags.isSchalkeEnabled ? "s04:" : nil,
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
                if let icon = presence.activityIcon.flatMap(UIImage.init(data:)) {
                    PixelThumb(image: icon, clip: .rect(cornerRadius: Radii.sm))
                }
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
            if let poster = film.poster.flatMap(UIImage.init(data:)) {
                PixelThumb(
                    image: poster,
                    clip: .rect(cornerRadius: Radii.sm),
                    width: Spacing.s3,
                    height: FooterLineMetrics.height
                )
            } else {
                Text("🎞")
            }
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
            if let thumb = record.thumb.flatMap(UIImage.init(data:)) {
                PixelThumb(image: thumb, clip: .rect(cornerRadius: Radii.sm))
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

private struct LastfmLine: View {
    let track: LastfmScrobbles.Track
    let total: String?

    var body: some View {
        FooterStatusLine(label: "last.fm:") {
            if let image = track.image.flatMap(UIImage.init(data:)) {
                PixelThumb(image: image, clip: .rect(cornerRadius: Radii.sm))
            } else {
                Text("♫")
            }
            Text(track.title)
                .lineLimit(1)
                .truncationMode(.tail)
            Text(track.artist)
                .lineLimit(1)
                .truncationMode(.tail)
                .opacity(Opacities.muted)
            if track.isNowPlaying {
                Text("▶")
                    .foregroundStyle(Palette.accent.s500)
                    .accessibilityLabel("now playing")
            }
            if track.isLoved {
                Text("♥")
                    .foregroundStyle(Palette.accent.s500)
                    .accessibilityLabel("loved")
            }
            if let total {
                Text("·").opacity(Opacities.subtle)
                Text(total)
                    .opacity(Opacities.subtle)
                    .accessibilityLabel("\(total) scrobbles")
            }
        }
    }
}

private struct SteamLine: View {
    let steam: SteamStatus
    let line: SteamStatus.Line

    var body: some View {
        FooterStatusLine(label: "steam:") {
            if let game = line.game {
                if let icon = game.icon.flatMap(UIImage.init(data:)) {
                    PixelThumb(image: icon, clip: .rect(cornerRadius: Radii.sm))
                } else {
                    Text("🎮")
                }
            } else if let avatar = steam.avatar.flatMap(UIImage.init(data:)) {
                PixelThumb(image: avatar, clip: .circle)
            }
            Text(line.game?.name ?? steam.name)
                .lineLimit(1)
                .truncationMode(.tail)
            if line.kind == .playing {
                Text("▶")
                    .foregroundStyle(Palette.accent.s500)
                    .accessibilityLabel("playing now")
            }
            if let detail = line.detail {
                Text("·").opacity(Opacities.subtle)
                if line.kind == .profile {
                    Text(detail).foregroundStyle(Palette.accent.s500)
                } else {
                    Text(detail).opacity(Opacities.subtle)
                }
            }
        }
    }
}

private struct YoutubeLine: View {
    let channel: YoutubeStatus.Channel
    let video: YoutubeStatus.Video

    var body: some View {
        FooterStatusLine(label: "youtube:") {
            if let avatar = channel.avatar.flatMap(UIImage.init(data:)) {
                PixelThumb(image: avatar, clip: .circle, label: channel.title)
            } else {
                Text("▶︎").accessibilityLabel(channel.title)
            }
            if let subscribers = channel.compactSubscriberCount {
                Text("(\(subscribers))")
                    .opacity(Opacities.subtle)
                    .accessibilityLabel("\(subscribers) subscribers")
            }
            Text("·").opacity(Opacities.subtle)
            Text(video.title)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}

private struct GithubLine: View {
    let avatar: Data?
    let activity: GithubStatus.Activity

    var body: some View {
        FooterStatusLine(label: "github:") {
            if let avatar = avatar.flatMap(UIImage.init(data:)) {
                PixelThumb(image: avatar, clip: .circle)
            }
            Text(activity.verb).opacity(Opacities.muted)
            Text(activity.repo)
                .lineLimit(1)
                .truncationMode(.middle)
            if let detail = activity.detail {
                Text(detail).opacity(Opacities.subtle)
            }
        }
    }
}

private struct RedditLine: View {
    let reddit: RedditKarma

    var body: some View {
        FooterStatusLine(label: "reddit:") {
            Text(reddit.handle)
                .lineLimit(1)
                .truncationMode(.tail)
            Text("·").opacity(Opacities.subtle)
            Text(reddit.compactKarma)
                .opacity(Opacities.subtle)
                .accessibilityLabel("\(reddit.karma) karma")
        }
    }
}

private struct XLine: View {
    let profile: XProfile
    let post: XPost

    var body: some View {
        FooterStatusLine(label: "x:") {
            if let avatar = profile.avatar.flatMap(UIImage.init(data:)) {
                PixelThumb(image: avatar, clip: .circle, label: profile.handle)
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

private struct FooterThumb<Clip: Shape>: View {
    let url: URL
    let clip: Clip
    var width: CGFloat = Typography.Size.md
    var height: CGFloat = Typography.Size.md
    var contentMode: ContentMode = .fill
    var isPixelated = false

    var body: some View {
        AsyncImage(url: url) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .interpolation(isPixelated ? .none : .high)
                    .aspectRatio(contentMode: contentMode)
            } else {
                Color.clear
            }
        }
        .frame(width: width, height: height)
        .clipShape(clip)
    }
}

private struct PixelThumb<Clip: Shape>: View {
    let image: UIImage
    let clip: Clip
    var width: CGFloat = Typography.Size.md
    var height: CGFloat = Typography.Size.md
    var contentMode: ContentMode = .fill
    var label: String?

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .interpolation(.none)
            .aspectRatio(contentMode: contentMode)
            .frame(width: width, height: height)
            .clipShape(clip)
            .accessibilityLabel(label ?? "")
            .accessibilityHidden(label == nil)
    }
}

private struct TrophyLine: View {
    let trophy: PsnTrophy

    @Environment(\.storyblokConfiguration) private var configuration

    var body: some View {
        FooterStatusLine(label: "psn:") {
            if let image = trophy.image.flatMap(UIImage.init(data:)) {
                PixelThumb(
                    image: image,
                    clip: Rectangle(),
                    width: Spacing.s4,
                    height: Spacing.s4,
                    contentMode: .fit
                )
            }
            if let type = trophy.type {
                FooterThumb(
                    url: configuration.siteOrigin.appending(path: "images/trophies/\(type).png"),
                    clip: Rectangle(),
                    width: Spacing.s3,
                    height: Spacing.s3,
                    contentMode: .fit,
                    isPixelated: true
                )
            } else {
                Text(trophy.badge)
            }
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

private struct SchalkeLine: View {
    let status: SchalkeStatus

    @Environment(\.storyblokConfiguration) private var configuration

    var body: some View {
        FooterStatusLine(label: "s04:") {
            if let fixture = status.fixture {
                crest(fixture.homeCrest)
                Text(fixture.score)
                    .lineLimit(1)
                    .truncationMode(.tail)
                crest(fixture.awayCrest)
            } else if let upcoming = status.upcoming {
                crest(upcoming.homeCrest)
                Text(upcoming.pairing)
                    .lineLimit(1)
                    .truncationMode(.tail)
                crest(upcoming.awayCrest)
                if let kickoff = upcoming.kickoffLabel() {
                    Text(kickoff)
                        .fixedSize()
                        .opacity(Opacities.subtle)
                }
            }
            if status.fixture != nil || status.upcoming != nil, status.standing != nil {
                Text("·").opacity(Opacities.subtle)
            }
            if let standing = status.standing {
                FooterThumb(
                    url: configuration.siteOrigin.appending(path: "images/football/\(standing.trend.rawValue).png"),
                    clip: Rectangle(),
                    width: Spacing.s2,
                    height: Spacing.s2,
                    contentMode: .fit,
                    isPixelated: true
                )
                .accessibilityLabel(trendLabel(for: standing))
                Text("\(standing.position).")
                if let points = standing.points {
                    Text("\(points) pts").opacity(Opacities.subtle)
                }
            }
        }
    }

    @ViewBuilder
    private func crest(_ data: Data?) -> some View {
        if let image = data.flatMap(UIImage.init(data:)) {
            Image(uiImage: image)
                .resizable()
                .interpolation(.none)
                .frame(width: Typography.Size.md, height: Typography.Size.md)
                .accessibilityHidden(true)
        }
    }

    private func trendLabel(for standing: SchalkeStanding) -> String {
        guard standing.trend != .same, let previous = standing.previousPosition else {
            return "unchanged"
        }
        return "\(standing.trend.rawValue) from \(previous)."
    }
}

private struct ClockLine: View {
    let weather: WeatherNow?

    @State private var now = Date()

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
        // Every line is at least as tall as the tallest thumb, so a poster or a trophy
        // no longer spreads its own line apart from the text-only ones.
        .frame(maxWidth: .infinity, minHeight: FooterLineMetrics.height)
        .padding(.horizontal, PageLayout.gutter)
    }
}

private enum FooterLineMetrics {
    /// The letterboxd poster, the tallest thumb a line carries.
    static let height: CGFloat = Spacing.s3 * 1.5
}

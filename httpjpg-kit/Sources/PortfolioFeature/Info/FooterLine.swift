import Foundation
import StoryblokCore

enum FooterLine: Identifiable {
    case discord(DiscordPresence)
    case film(LetterboxdFilm)
    case record(DiscogsRelease)
    case scrobble(LastfmScrobbles.Track, total: String?)
    case steam(SteamStatus, SteamStatus.Line)
    case youtube(YoutubeStatus.Channel, YoutubeStatus.Video)
    case github(Data?, GithubStatus.Activity)
    case reddit(RedditKarma)
    case x(XProfile, XPost)
    case trophy(PsnTrophy)
    case schalke(SchalkeStatus)

    var id: String {
        switch self {
        case .discord: return "discord"
        case .film: return "letterboxd"
        case .record: return "discogs"
        case .scrobble: return "lastfm"
        case .steam: return "steam"
        case .youtube: return "youtube"
        case .github: return "github"
        case .reddit: return "reddit"
        case .x: return "x"
        case .trophy: return "psn"
        case .schalke: return "schalke"
        }
    }

    var isLive: Bool {
        switch self {
        case .discord(let presence): return presence.status != .offline
        case .scrobble(let track, _): return track.isNowPlaying
        case .steam(_, let line): return line.kind == .playing
        default: return false
        }
    }

    var date: Date? {
        switch self {
        case .film(let film): return film.watchedDate
        case .record(let record): return record.addedAt
        case .scrobble(let track, _): return track.scrobbledAt
        case .steam(_, let line): return line.game?.lastPlayedAt
        case .youtube(_, let video): return video.publishedAt
        case .github(_, let activity): return activity.createdAt
        case .x(_, let post): return post.createdAt
        case .trophy(let trophy): return trophy.earnedAt
        case .schalke(let status): return status.fixture?.playedAt ?? status.upcoming?.kickoff
        case .discord, .reddit: return nil
        }
    }
}

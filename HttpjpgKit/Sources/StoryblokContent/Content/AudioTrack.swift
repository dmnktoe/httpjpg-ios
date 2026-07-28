import Foundation
import SwiftUI

/// One playable piece of audio, flattened out of a `music_player` blok.
///
/// Deliberately free of blok vocabulary — the player screens work with this,
/// not with `MusicPlayerBlok`, so the playback stack never has to know where a
/// track came from.
public struct AudioTrack: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let artist: String?
    public let streamURL: URL
    public let artworkURL: URL?

    public init(id: String, title: String, artist: String?, streamURL: URL, artworkURL: URL?) {
        self.id = id
        self.title = title
        self.artist = artist
        self.streamURL = streamURL
        self.artworkURL = artworkURL
    }
}

/// How a blok asks the app to start playing.
///
/// The blok renderers live in `StoryblokContent`, but the audio player is app
/// state in `PortfolioFeature` — a lower layer cannot import it back. This
/// environment closure is the seam: `SbMusicPlayerView` calls it, `RootView`
/// supplies it. The default is a no-op so previews and tests render without a
/// player attached.
private struct PlayAudioTrackKey: EnvironmentKey {
    static let defaultValue: @MainActor (AudioTrack) -> Void = { _ in }
}

public extension EnvironmentValues {
    var playAudioTrack: @MainActor (AudioTrack) -> Void {
        get { self[PlayAudioTrackKey.self] }
        set { self[PlayAudioTrackKey.self] = newValue }
    }
}

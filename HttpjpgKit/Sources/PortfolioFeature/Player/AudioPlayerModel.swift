import AVFoundation
import Foundation
import MediaPlayer
import Observation
import StoryblokContent
import UIKit

/// The app's one audio player.
///
/// Owns a single `AVPlayer` for the lifetime of the app, so a track keeps
/// playing while the reader navigates — which is the entire point of having a
/// mini bar instead of an inline transport. Views never touch `AVPlayer`;
/// they read the published state and call the intent methods.
///
/// The model is also the app's face to the system: it feeds
/// `MPNowPlayingInfoCenter` (lock screen, Control Center, AirPods labels) and
/// answers `MPRemoteCommandCenter` (the buttons on all of those). Artwork is
/// downloaded once here and shared by the bar, the full-screen player and the
/// lock screen — three views, one fetch.
@MainActor
@Observable
public final class AudioPlayerModel {
    public private(set) var track: AudioTrack?
    public private(set) var isPlaying = false
    public private(set) var currentTime: TimeInterval = 0
    public private(set) var duration: TimeInterval = 0
    /// The track's cover, downloaded once per track.
    public private(set) var artwork: UIImage?
    /// Whether the full-screen player is up. Settable because the sheet's
    /// dismissal writes it back through a binding.
    public var isExpanded = false

    @ObservationIgnored private let player = AVPlayer()
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var endObserver: NSObjectProtocol?
    @ObservationIgnored private var artworkTask: Task<Void, Never>?

    public init() {
        // `.playback` is what makes audio survive the silent switch — a music
        // player that mutes with the ringer reads as broken.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        registerRemoteCommands()
    }

    /// Starts a track, or — for the track already loaded — just resumes it, so
    /// tapping PLAY on the same blok twice does not restart the song.
    public func play(_ newTrack: AudioTrack) {
        if track != newTrack {
            track = newTrack
            currentTime = 0
            duration = 0
            artwork = nil
            player.replaceCurrentItem(with: AVPlayerItem(url: newTrack.streamURL))
            installObservers()
            loadArtwork(for: newTrack)
        }
        try? AVAudioSession.sharedInstance().setActive(true)
        player.play()
        isPlaying = true
        publishNowPlaying()
    }

    public func togglePlayPause() {
        guard track != nil else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
        publishPlaybackState()
    }

    public func seek(to seconds: TimeInterval) {
        let clamped = max(0, min(seconds, duration > 0 ? duration : seconds))
        currentTime = clamped
        player.seek(
            to: CMTime(seconds: clamped, preferredTimescale: 600),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
        publishPlaybackState()
    }

    /// Tears the whole thing down — bar, lock screen entry, everything. The
    /// full-screen player's close is `isExpanded = false`; this is the ✕.
    public func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        removeObservers()
        artworkTask?.cancel()
        track = nil
        artwork = nil
        isPlaying = false
        isExpanded = false
        currentTime = 0
        duration = 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    // MARK: - System integration

    /// The lock screen's transport calls straight back into the same intents
    /// the on-screen buttons use. Handlers arrive on the main thread, so the
    /// isolation hop is a statement of fact.
    private func registerRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.track != nil, !self.isPlaying else { return .commandFailed }
                self.togglePlayPause()
                return .success
            }
        }
        center.pauseCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.track != nil, self.isPlaying else { return .commandFailed }
                self.togglePlayPause()
                return .success
            }
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.track != nil else { return .commandFailed }
                self.togglePlayPause()
                return .success
            }
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            MainActor.assumeIsolated {
                guard let self, self.track != nil,
                      let event = event as? MPChangePlaybackPositionCommandEvent
                else { return .commandFailed }
                self.seek(to: event.positionTime)
                return .success
            }
        }
        center.skipForwardCommand.preferredIntervals = [15]
        center.skipForwardCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.track != nil else { return .commandFailed }
                self.seek(to: self.currentTime + 15)
                return .success
            }
        }
        center.skipBackwardCommand.preferredIntervals = [15]
        center.skipBackwardCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.track != nil else { return .commandFailed }
                self.seek(to: self.currentTime - 15)
                return .success
            }
        }
    }

    /// Full rebuild of the now-playing entry — on track change, artwork
    /// arrival, and the first resolved duration.
    private func publishNowPlaying() {
        guard let track else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
        ]
        if let artist = track.artist {
            info[MPMediaItemPropertyArtist] = artist
        }
        if let artwork {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artwork.size) { _ in
                artwork
            }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    /// Cheap update for pause/seek — the system extrapolates elapsed time from
    /// the rate, so only those two fields need refreshing.
    private func publishPlaybackState() {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func loadArtwork(for track: AudioTrack) {
        artworkTask?.cancel()
        guard let url = track.artworkURL else { return }
        artworkTask = Task { [weak self] in
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let image = UIImage(data: data),
                  !Task.isCancelled
            else { return }
            guard let self, self.track == track else { return }
            self.artwork = image
            self.publishNowPlaying()
        }
    }

    // MARK: - Player observation

    private func installObservers() {
        removeObservers()

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            // The observer queue is main, so this hop is a statement of fact,
            // not a wish.
            MainActor.assumeIsolated {
                guard let self else { return }
                self.currentTime = time.seconds
                if self.duration == 0,
                   let seconds = self.player.currentItem?.duration.seconds,
                   seconds.isFinite, seconds > 0 {
                    self.duration = seconds
                    self.publishNowPlaying()
                }
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.isPlaying = false
                self.seek(to: 0)
            }
        }
    }

    private func removeObservers() {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
    }
}

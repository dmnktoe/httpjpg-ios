import AVFoundation
import Foundation
import MediaPlayer
import Observation
import StoryblokCore
import UIKit

@MainActor
@Observable
public final class AudioPlayerModel {
    public private(set) var track: AudioTrack?
    public private(set) var isPlaying = false
    public private(set) var currentTime: TimeInterval = 0
    public private(set) var duration: TimeInterval = 0

    public private(set) var artwork: UIImage?

    public var isExpanded = false

    @ObservationIgnored private let player = AVPlayer()
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var endObserver: NSObjectProtocol?
    @ObservationIgnored private var artworkTask: Task<Void, Never>?

    public init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        registerRemoteCommands()
    }

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

    private func installObservers() {
        removeObservers()

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in

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

import AVFoundation
import Foundation
import Observation
import StoryblokContent

/// The app's one audio player.
///
/// Owns a single `AVPlayer` for the lifetime of the app, so a track keeps
/// playing while the reader navigates — which is the entire point of having a
/// mini bar instead of an inline transport. Views never touch `AVPlayer`;
/// they read the published state and call the intent methods.
@MainActor
@Observable
public final class AudioPlayerModel {
    public private(set) var track: AudioTrack?
    public private(set) var isPlaying = false
    public private(set) var currentTime: TimeInterval = 0
    public private(set) var duration: TimeInterval = 0
    /// Whether the full-screen player is up. Settable because the sheet's
    /// dismissal writes it back through a binding.
    public var isExpanded = false

    @ObservationIgnored private let player = AVPlayer()
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var endObserver: NSObjectProtocol?

    public init() {
        // `.playback` is what makes audio survive the silent switch — a music
        // player that mutes with the ringer reads as broken.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
    }

    /// Starts a track, or — for the track already loaded — just resumes it, so
    /// tapping PLAY on the same blok twice does not restart the song.
    public func play(_ newTrack: AudioTrack) {
        if track != newTrack {
            track = newTrack
            currentTime = 0
            duration = 0
            player.replaceCurrentItem(with: AVPlayerItem(url: newTrack.streamURL))
            installObservers()
        }
        try? AVAudioSession.sharedInstance().setActive(true)
        player.play()
        isPlaying = true
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
    }

    public func seek(to seconds: TimeInterval) {
        let clamped = max(0, min(seconds, duration > 0 ? duration : seconds))
        currentTime = clamped
        player.seek(
            to: CMTime(seconds: clamped, preferredTimescale: 600),
            toleranceBefore: .zero,
            toleranceAfter: .zero
        )
    }

    /// Tears the whole thing down — bar included. The full-screen player's
    /// close is `isExpanded = false`; this is the ✕ on the bar.
    public func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        removeObservers()
        track = nil
        isPlaying = false
        isExpanded = false
        currentTime = 0
        duration = 0
    }

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
                if let seconds = self.player.currentItem?.duration.seconds,
                   seconds.isFinite, seconds > 0 {
                    self.duration = seconds
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

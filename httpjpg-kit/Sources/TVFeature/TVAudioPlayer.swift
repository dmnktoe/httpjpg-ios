import AVFoundation
import Observation
import StoryblokCore

@MainActor
@Observable
final class TVAudioPlayer {
    let tracks: [AudioTrack]

    private(set) var index: Int
    private(set) var isPlaying = false
    private(set) var progress: Double = 0

    @ObservationIgnored private let player = AVPlayer()
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var endObserver: NSObjectProtocol?

    init(tracks: [AudioTrack], start: AudioTrack) {
        self.tracks = tracks
        index = tracks.firstIndex(of: start) ?? 0
    }

    var track: AudioTrack? {
        tracks.indices.contains(index) ? tracks[index] : nil
    }

    var hasSeveralTracks: Bool {
        tracks.count > 1
    }

    func start() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)

        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            MainActor.assumeIsolated {
                guard let self,
                      let seconds = self.player.currentItem?.duration.seconds,
                      seconds.isFinite, seconds > 0
                else { return }
                self.progress = min(max(time.seconds / seconds, 0), 1)
            }
        }
        loadCurrentTrack()
    }

    func togglePlayPause() {
        guard track != nil else { return }
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }

    func skip(_ offset: Int) {
        guard hasSeveralTracks else { return }
        index = (index + offset + tracks.count) % tracks.count
        loadCurrentTrack()
    }

    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        timeObserver = nil
        removeEndObserver()
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func loadCurrentTrack() {
        guard let track else { return }
        progress = 0
        let item = AVPlayerItem(url: track.streamURL)
        player.replaceCurrentItem(with: item)

        removeEndObserver()
        endObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: item,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.trackEnded()
            }
        }

        player.play()
        isPlaying = true
    }

    private func trackEnded() {
        if hasSeveralTracks {
            skip(1)
        } else {
            player.seek(to: .zero)
            isPlaying = false
            progress = 0
        }
    }

    private func removeEndObserver() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = nil
    }
}

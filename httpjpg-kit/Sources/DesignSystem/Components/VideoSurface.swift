import AVFoundation
import AVKit
import Combine
import SwiftUI

/// Native video playback with the CMS playback flags applied. `LoopingVideoPlayer`
/// stays the right choice for decorative background clips; this one honours
/// controls, autoplay, loop and mute the way the `video` blok configures them.
public struct VideoSurface: View {
    private let url: URL
    private let posterURL: URL?
    private let aspectRatio: CGFloat
    private let showsControls: Bool
    private let autoPlays: Bool
    private let loops: Bool
    private let isMuted: Bool
    private let accessibilityText: String?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?
    @State private var isPosterVisible = true

    public init(
        url: URL,
        posterURL: URL? = nil,
        aspectRatio: CGFloat = PageLayout.mediaAspectRatio,
        showsControls: Bool = true,
        autoPlays: Bool = false,
        loops: Bool = false,
        isMuted: Bool = false,
        accessibilityText: String? = nil
    ) {
        self.url = url
        self.posterURL = posterURL
        self.aspectRatio = aspectRatio
        self.showsControls = showsControls
        self.autoPlays = autoPlays
        self.loops = loops
        self.isMuted = isMuted
        self.accessibilityText = accessibilityText
    }

    public var body: some View {
        surface
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay { poster }
            .clipped()
            .onAppear(perform: start)
            .onDisappear { player?.pause() }
            .onReceive(playbackStatus) { status in
                if status == .playing { isPosterVisible = false }
            }
            .accessibilityLabel(accessibilityText ?? "")
    }

    @ViewBuilder
    private var surface: some View {
        if let player {
            if showsControls {
                VideoPlayer(player: player)
            } else {
                PlayerLayerView(player: player)
                    .allowsHitTesting(false)
            }
        } else {
            Color.black
        }
    }

    @ViewBuilder
    private var poster: some View {
        if isPosterVisible, let posterURL {
            RemoteImage(url: posterURL, aspectRatio: aspectRatio, contentMode: .fit)
                // Taps have to reach the transport controls underneath.
                .allowsHitTesting(false)
        }
    }

    private var playbackStatus: AnyPublisher<AVPlayer.TimeControlStatus, Never> {
        guard let player else { return Empty().eraseToAnyPublisher() }
        return player.publisher(for: \.timeControlStatus).eraseToAnyPublisher()
    }

    private func start() {
        if player == nil {
            let queue = AVQueuePlayer()
            queue.isMuted = isMuted
            let item = AVPlayerItem(url: url)
            if loops {
                looper = AVPlayerLooper(player: queue, templateItem: item)
            } else {
                queue.replaceCurrentItem(with: item)
            }
            player = queue
        }
        // Matches the web renderer, which drops autoplay under reduced motion.
        guard autoPlays, !reduceMotion else { return }
        player?.play()
    }
}

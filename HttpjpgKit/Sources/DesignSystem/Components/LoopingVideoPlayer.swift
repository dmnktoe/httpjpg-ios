import AVKit
import SwiftUI

/// A clip with no chrome: muted, looping, autoplaying — the web's
/// `<video autoplay muted loop playsinline>`, used for video slides in every
/// carousel.
///
/// `allowsHitTesting(false)` is what keeps it chromeless — `VideoPlayer` only
/// shows its controls on touch, and the touches go to the carousel instead.
/// Muted playback shares the audio session politely, so a running music track
/// keeps playing over it. The aspect box matters: a player view has no
/// intrinsic size, and without it a lone video slide lays out at zero height.
public struct LoopingVideoPlayer: View {
    private let url: URL
    private let aspectRatio: CGFloat

    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?

    public init(url: URL, aspectRatio: CGFloat) {
        self.url = url
        self.aspectRatio = aspectRatio
    }

    public var body: some View {
        Color.black
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay {
                if let player {
                    VideoPlayer(player: player)
                        .allowsHitTesting(false)
                }
            }
            .clipped()
            // Same as RemoteImage: clipping trims pixels, not hit testing, and
            // an overflowing player must not steal taps from its neighbours.
            .contentShape(Rectangle())
            .onAppear(perform: start)
            .onDisappear { player?.pause() }
            .accessibilityHidden(true)
    }

    private func start() {
        if player == nil {
            let queue = AVQueuePlayer()
            queue.isMuted = true
            looper = AVPlayerLooper(player: queue, templateItem: AVPlayerItem(url: url))
            player = queue
        }
        player?.play()
    }
}

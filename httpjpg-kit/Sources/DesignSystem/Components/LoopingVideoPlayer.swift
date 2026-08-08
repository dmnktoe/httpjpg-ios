import AVFoundation
import SwiftUI

public struct LoopingVideoPlayer: View {
    private let url: URL
    private let aspectRatio: CGFloat

    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?
    @State private var isReady = false

    public init(url: URL, aspectRatio: CGFloat) {
        self.url = url
        self.aspectRatio = aspectRatio
    }

    public var body: some View {
        Color.black
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay {
                if let player {
                    PlayerLayerView(player: player) { isReady = $0 }
                        .allowsHitTesting(false)
                }
            }
            .overlay {
                // The player layer renders a hard black box until its first
                // frame is decoded; pulse the skeleton over it until then.
                if !isReady {
                    SkeletonBlock(height: nil)
                        .transition(.opacity)
                }
            }
            .animation(Motion.mediaIn, value: isReady)
            .clipped()
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

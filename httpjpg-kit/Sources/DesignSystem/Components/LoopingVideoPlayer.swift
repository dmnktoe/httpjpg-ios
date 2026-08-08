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
            .task { await start() }
            .onDisappear { player?.pause() }
            .accessibilityHidden(true)
    }

    // Explicitly main-actor: resolving the URL suspends, and the player and the
    // looper have to be assigned back on the main actor when it resumes.
    @MainActor
    private func start() async {
        if player == nil {
            // Plays the stored copy rather than the remote URL: AVFoundation
            // ignores URLCache, so an uncached loop re-downloads on every pass
            // through the carousel. The skeleton above covers the first fetch.
            let source = await VideoCache.shared.localURL(for: url)
            guard !Task.isCancelled else { return }

            let queue = AVQueuePlayer()
            queue.isMuted = true
            looper = AVPlayerLooper(player: queue, templateItem: AVPlayerItem(url: source))
            player = queue
        }
        player?.play()
    }
}

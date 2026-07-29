import AVFoundation
import SwiftUI
import UIKit

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
                    PlayerLayerView(player: player)
                        .allowsHitTesting(false)
                }
            }
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

/// AVKit's `VideoPlayer` wraps an `AVPlayerViewController`, which claims status
/// bar appearance for the whole window and hides it — so a card carousel with a
/// video slide knocked out the status bar for the rest of the session, and every
/// slide change churned the view controller hierarchy behind the glass pills.
/// An `AVPlayerLayer` carries no view controller and no playback chrome.
private struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerLayerHost {
        let host = PlayerLayerHost()
        host.playerLayer.videoGravity = .resizeAspect
        host.playerLayer.player = player
        return host
    }

    func updateUIView(_ host: PlayerLayerHost, context: Context) {
        if host.playerLayer.player !== player {
            host.playerLayer.player = player
        }
    }
}

private final class PlayerLayerHost: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    var playerLayer: AVPlayerLayer {
        // Safe: `layerClass` above pins the backing layer to AVPlayerLayer.
        layer as! AVPlayerLayer
    }
}

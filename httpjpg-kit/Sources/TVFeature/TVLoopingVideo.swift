#if os(tvOS) || os(iOS)
import AVFoundation
import SwiftUI
import UIKit

// SwiftUI's VideoPlayer always brings its transport bar; a silent loop behind
// other content needs the bare layer.
struct TVLoopingVideo: UIViewRepresentable {
    let url: URL

    final class Coordinator {
        var looper: AVPlayerLooper?
    }

    final class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }

        var playerLayer: AVPlayerLayer? { layer as? AVPlayerLayer }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        let player = AVQueuePlayer()
        player.isMuted = true
        context.coordinator.looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
        view.playerLayer?.player = player
        view.playerLayer?.videoGravity = .resizeAspectFill
        player.play()
        return view
    }

    func updateUIView(_ view: PlayerView, context: Context) {}

    static func dismantleUIView(_ view: PlayerView, coordinator: Coordinator) {
        view.playerLayer?.player?.pause()
        view.playerLayer?.player = nil
        coordinator.looper = nil
    }
}
#endif

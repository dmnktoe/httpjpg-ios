import AVFoundation
import SwiftUI
import UIKit

/// A bare `AVPlayerLayer`. AVKit's `VideoPlayer` always draws transport
/// controls, so chrome-less playback has to go through the layer directly.
struct PlayerLayerView: UIViewRepresentable {
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

final class PlayerLayerHost: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}

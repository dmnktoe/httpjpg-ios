import AVFoundation
import SwiftUI
import UIKit

struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer
    var onReadyChange: ((Bool) -> Void)?

    func makeUIView(context: Context) -> PlayerLayerHost {
        let host = PlayerLayerHost()
        host.playerLayer.videoGravity = .resizeAspect
        host.playerLayer.player = player
        host.onReadyChange = onReadyChange
        host.observeReadiness()
        return host
    }

    func updateUIView(_ host: PlayerLayerHost, context: Context) {
        host.onReadyChange = onReadyChange
        if host.playerLayer.player !== player {
            host.playerLayer.player = player
        }
    }
}

final class PlayerLayerHost: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }

    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    var onReadyChange: ((Bool) -> Void)?
    private var readyObservation: NSKeyValueObservation?

    func observeReadiness() {
        readyObservation = playerLayer.observe(\.isReadyForDisplay, options: [.initial, .new]) { [weak self] layer, _ in
            let isReady = layer.isReadyForDisplay
            DispatchQueue.main.async { self?.onReadyChange?(isReady) }
        }
    }
}

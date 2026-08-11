import AVFoundation
import Combine
import SwiftUI
import Tokens

private struct MediaHeldKey: EnvironmentKey {
    static let defaultValue = false
}

public extension EnvironmentValues {
    var mediaHeld: Bool {
        get { self[MediaHeldKey.self] }
        set { self[MediaHeldKey.self] = newValue }
    }
}

public struct LoopingVideoPlayer: View {
    private let url: URL
    private let aspectRatio: CGFloat
    private let isActive: Bool
    private let onFinished: (() -> Void)?

    @State private var player: AVPlayer?
    @State private var looper: AVPlayerLooper?
    @State private var item: AVPlayerItem?
    @State private var isReady = false

    @Environment(\.mediaHeld) private var isHeld

    public init(
        url: URL,
        aspectRatio: CGFloat,
        isActive: Bool = true,
        onFinished: (() -> Void)? = nil
    ) {
        self.url = url
        self.aspectRatio = aspectRatio
        self.isActive = isActive
        self.onFinished = onFinished
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
                if !isReady {
                    SkeletonBlock(height: nil)
                        .transition(.opacity)
                }
            }
            .animation(Motion.mediaIn, value: isReady)
            .clipped()
            .contentShape(Rectangle())
            .task(id: isActive) { await start() }
            .onChange(of: isHeld) { _, held in
                guard isActive, let player, item != nil else { return }
                if held {
                    player.pause()
                } else {
                    player.play()
                }
            }
            .onReceive(endOfPlayback) { notification in
                guard isActive, let item,
                      let ended = notification.object as? AVPlayerItem, ended === item
                else { return }
                onFinished?()
            }
            .onDisappear { player?.pause() }
            .accessibilityHidden(true)
    }

    private var endOfPlayback: some Publisher<Notification, Never> {
        let center = NotificationCenter.default
        return center.publisher(for: AVPlayerItem.didPlayToEndTimeNotification)
            .merge(with: center.publisher(for: AVPlayerItem.failedToPlayToEndTimeNotification))
            .receive(on: DispatchQueue.main)
    }

    @MainActor
    private func start() async {
        let isFirstStart = player == nil
        if isFirstStart {
            let source = await VideoCache.shared.localURL(for: url)
            guard !Task.isCancelled else { return }

            let playerItem = AVPlayerItem(url: source)
            let resolved: AVPlayer
            if onFinished == nil {
                let queue = AVQueuePlayer()
                looper = AVPlayerLooper(player: queue, templateItem: playerItem)
                resolved = queue
            } else {
                resolved = AVPlayer(playerItem: playerItem)
            }
            resolved.isMuted = true
            item = playerItem
            player = resolved
        }

        guard let player else { return }
        settle(player, rewinding: !isFirstStart)
    }

    @MainActor
    private func settle(_ player: AVPlayer, rewinding: Bool) {
        guard isActive else {
            player.pause()
            player.seek(to: .zero)
            return
        }
        if rewinding {
            player.seek(to: .zero)
        }
        if !isHeld {
            player.play()
        }
    }
}

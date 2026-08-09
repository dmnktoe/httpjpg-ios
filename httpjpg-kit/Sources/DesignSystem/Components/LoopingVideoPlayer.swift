import AVFoundation
import Combine
import SwiftUI

public struct LoopingVideoPlayer: View {
    private let url: URL
    private let aspectRatio: CGFloat
    private let isActive: Bool
    private let onFinished: (() -> Void)?

    @State private var player: AVPlayer?
    @State private var looper: AVPlayerLooper?

    /// Kept rather than read back off the player, so the end notification can be
    /// matched even once the player has moved past the item.
    @State private var item: AVPlayerItem?

    @State private var isReady = false

    /// `onFinished` turns the loop into a single pass that reports when it is
    /// done; `isActive` false pauses and rewinds instead of looping off-screen.
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
            // Keyed on isActive: resolving the URL suspends, and a plain .task
            // would resume holding the value from when the slide appeared.
            .task(id: isActive) { await start() }
            .onReceive(endOfPlayback) { notification in
                guard let item, let ended = notification.object as? AVPlayerItem,
                      ended === item
                else { return }
                onFinished?()
            }
            .onDisappear { player?.pause() }
            .accessibilityHidden(true)
    }

    /// A failed item reports like a finished one: playback that never ends must
    /// not strand the show. AVFoundation posts both on whichever thread it is
    /// on, and the handler drives a carousel from here.
    private var endOfPlayback: some Publisher<Notification, Never> {
        let center = NotificationCenter.default
        return center.publisher(for: AVPlayerItem.didPlayToEndTimeNotification)
            .merge(with: center.publisher(for: AVPlayerItem.failedToPlayToEndTimeNotification))
            .receive(on: DispatchQueue.main)
    }

    // Explicitly main-actor: resolving the URL suspends, and the player and the
    // looper have to be assigned back on the main actor when it resumes.
    @MainActor
    private func start() async {
        let isFirstStart = player == nil
        if isFirstStart {
            // Plays the stored copy rather than the remote URL: AVFoundation
            // ignores URLCache, so an uncached loop re-downloads on every pass
            // through the carousel. The skeleton above covers the first fetch.
            let source = await VideoCache.shared.localURL(for: url)
            guard !Task.isCancelled else { return }

            let playerItem = AVPlayerItem(url: source)
            let resolved: AVPlayer
            if onFinished == nil {
                // AVPlayerLooper owns the queue it is given, so it starts empty.
                let queue = AVQueuePlayer()
                looper = AVPlayerLooper(player: queue, templateItem: playerItem)
                resolved = queue
            } else {
                // A single pass wants no queue behind it — an emptying queue
                // ends the item on its own terms rather than pausing on it.
                resolved = AVPlayer(playerItem: playerItem)
            }
            resolved.isMuted = true
            item = playerItem
            player = resolved
        }

        guard let player else { return }
        // Seeking a fresh item would only fight the looper.
        settle(player, rewinding: !isFirstStart)
    }

    /// Synchronous on purpose: `seek(to:)` also has an `async` overload, and
    /// inside an `async` function that is the one overload resolution picks.
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
        player.play()
    }
}

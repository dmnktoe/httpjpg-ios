import AVFoundation
import Combine
import SwiftUI

public struct LoopingVideoPlayer: View {
    private let url: URL
    private let aspectRatio: CGFloat
    private let isActive: Bool
    private let onFinished: (@MainActor () -> Void)?

    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?
    @State private var isReady = false

    /// `onFinished` turns the loop into a single pass: the clip plays once from
    /// the top and reports when it is done, so a carousel can wait for it
    /// instead of swiping past mid-playback. `isActive` false pauses and rewinds
    /// rather than looping off-screen.
    public init(
        url: URL,
        aspectRatio: CGFloat,
        isActive: Bool = true,
        onFinished: (@MainActor () -> Void)? = nil
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
            // Keyed on isActive rather than paired with an onChange: resolving
            // the URL suspends, and a plain .task would resume holding whatever
            // isActive read when the slide first appeared.
            .task(id: isActive) { await start() }
            .onReceive(endOfPlayback) { notification in
                guard let item = notification.object as? AVPlayerItem,
                      item === player?.currentItem
                else { return }
                onFinished?()
            }
            .onDisappear { player?.pause() }
            .accessibilityHidden(true)
    }

    /// Playback that never finishes must not strand the show, so a failed item
    /// reports the same way a finished one does.
    private var endOfPlayback: some Publisher<Notification, Never> {
        let center = NotificationCenter.default
        return center.publisher(for: AVPlayerItem.didPlayToEndTimeNotification)
            .merge(with: center.publisher(for: AVPlayerItem.failedToPlayToEndTimeNotification))
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

            let item = AVPlayerItem(url: source)
            let queue: AVQueuePlayer
            if onFinished == nil {
                // The looper owns the queue, so it has to start out empty.
                queue = AVQueuePlayer()
                looper = AVPlayerLooper(player: queue, templateItem: item)
            } else {
                queue = AVQueuePlayer(items: [item])
                queue.actionAtItemEnd = .pause
            }
            queue.isMuted = true
            player = queue
        }

        guard let player else { return }
        guard isActive else {
            player.pause()
            player.seek(to: .zero)
            return
        }
        // A clip coming back on screen starts from the top; one that has never
        // played is already there, and seeking a looped item would fight the
        // looper for no gain.
        if !isFirstStart {
            player.seek(to: .zero)
        }
        player.play()
    }
}

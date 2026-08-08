import AVFoundation
import AVKit
import SwiftUI

/// Native video playback with the CMS playback flags applied. `LoopingVideoPlayer`
/// stays the right choice for decorative background clips; this one honours
/// controls, autoplay, loop and mute the way the `video` blok configures them.
public struct VideoSurface: View {
    private let url: URL
    private let posterURL: URL?
    private let aspectRatio: CGFloat
    private let showsControls: Bool
    private let autoPlays: Bool
    private let loops: Bool
    private let isMuted: Bool
    private let accessibilityText: String?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Created up front rather than in start(): the poster subscription below
    // needs a publisher whose source never changes identity mid-flight.
    @State private var player = AVQueuePlayer()
    @State private var looper: AVPlayerLooper?
    @State private var isConfigured = false
    @State private var isPosterVisible = true

    public init(
        url: URL,
        posterURL: URL? = nil,
        aspectRatio: CGFloat = PageLayout.mediaAspectRatio,
        showsControls: Bool = true,
        autoPlays: Bool = false,
        loops: Bool = false,
        isMuted: Bool = false,
        accessibilityText: String? = nil
    ) {
        self.url = url
        self.posterURL = posterURL
        self.aspectRatio = aspectRatio
        self.showsControls = showsControls
        self.autoPlays = autoPlays
        self.loops = loops
        self.isMuted = isMuted
        self.accessibilityText = accessibilityText
    }

    public var body: some View {
        surface
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay { poster }
            .clipped()
            .onAppear(perform: start)
            .onDisappear { player.pause() }
            .onReceive(player.publisher(for: \.timeControlStatus)) { status in
                if status == .playing { isPosterVisible = false }
            }
            .modifier(OptionalAccessibilityLabel(text: accessibilityText))
    }

    @ViewBuilder
    private var surface: some View {
        if showsControls {
            VideoPlayer(player: player)
        } else {
            PlayerLayerView(player: player)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var poster: some View {
        if isPosterVisible, let posterURL {
            RemoteImage(url: posterURL, aspectRatio: aspectRatio, contentMode: .fit)
                // Taps have to reach the transport controls underneath.
                .allowsHitTesting(false)
        }
    }

    private func start() {
        if !isConfigured {
            isConfigured = true
            player.isMuted = isMuted
            let item = AVPlayerItem(url: url)
            if loops {
                looper = AVPlayerLooper(player: player, templateItem: item)
            } else {
                player.replaceCurrentItem(with: item)
            }
        }
        // Matches the web renderer, which drops autoplay under reduced motion.
        guard autoPlays, !reduceMotion else { return }
        player.play()
    }
}

/// An empty label would replace AVKit's own, so the label is only applied when
/// the CMS actually supplied alt text.
private struct OptionalAccessibilityLabel: ViewModifier {
    let text: String?

    func body(content: Content) -> some View {
        if let text, !text.isEmpty {
            content.accessibilityLabel(text)
        } else {
            content
        }
    }
}

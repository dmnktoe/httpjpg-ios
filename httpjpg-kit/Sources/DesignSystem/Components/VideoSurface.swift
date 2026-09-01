import AVFoundation
import AVKit
import SwiftUI

public struct VideoSurface: View {
    private let url: URL
    private let posterURL: URL?
    private let aspectRatio: CGFloat?
    private let showsControls: Bool
    private let autoPlays: Bool
    private let loops: Bool
    private let isMuted: Bool
    private let accessibilityText: String?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var player = AVQueuePlayer()
    @State private var looper: AVPlayerLooper?
    @State private var isConfigured = false
    @State private var isPosterVisible = true

    public init(
        url: URL,
        posterURL: URL? = nil,
        aspectRatio: CGFloat? = PageLayout.mediaAspectRatio,
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
        Group {
            if let aspectRatio {
                surface
                    .aspectRatio(aspectRatio, contentMode: .fit)
            } else {
                surface
                    .frame(maxWidth: .infinity)
            }
        }
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
            RemoteImage(
                url: posterURL,
                aspectRatio: aspectRatio ?? PageLayout.mediaAspectRatio,
                contentMode: .fit
            )
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
        guard autoPlays, !reduceMotion else { return }
        player.play()
    }
}

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

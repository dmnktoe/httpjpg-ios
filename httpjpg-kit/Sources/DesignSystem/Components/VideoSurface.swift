import AVFoundation
import AVKit
import SwiftUI

public struct VideoSurface: View {
    public enum Layout: Sendable {
        case fitted
        case contained
    }

    private let url: URL
    private let posterURL: URL?
    private let aspectRatio: CGFloat
    private let layout: Layout
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
    @State private var measuredAspectRatio: CGFloat?

    public init(
        url: URL,
        posterURL: URL? = nil,
        aspectRatio: CGFloat = PageLayout.mediaAspectRatio,
        layout: Layout = .fitted,
        showsControls: Bool = true,
        autoPlays: Bool = false,
        loops: Bool = false,
        isMuted: Bool = false,
        accessibilityText: String? = nil
    ) {
        self.url = url
        self.posterURL = posterURL
        self.aspectRatio = aspectRatio
        self.layout = layout
        self.showsControls = showsControls
        self.autoPlays = autoPlays
        self.loops = loops
        self.isMuted = isMuted
        self.accessibilityText = accessibilityText
    }

    public var body: some View {
        framedSurface
            .overlay { poster }
            .overlay {
                if showsControls, layout == .fitted {
                    VideoPlaybackControls(player: player, showsControls: true)
                }
            }
            .clipped()
            .onAppear(perform: start)
            .onDisappear { player.pause() }
            .onReceive(player.publisher(for: \.timeControlStatus)) { status in
                if status == .playing { isPosterVisible = false }
            }
            .task(id: url) { await measureNaturalAspect() }
            .modifier(OptionalAccessibilityLabel(text: accessibilityText))
    }

    private var resolvedAspectRatio: CGFloat {
        measuredAspectRatio ?? aspectRatio
    }

    private var videoGravity: AVLayerVideoGravity {
        switch layout {
        case .fitted: .resizeAspectFill
        case .contained: .resizeAspect
        }
    }

    @ViewBuilder
    private var framedSurface: some View {
        switch layout {
        case .fitted:
            surface
                .aspectRatio(resolvedAspectRatio, contentMode: .fit)
                .frame(maxWidth: .infinity)
        case .contained:
            surface
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var surface: some View {
        if showsControls, layout == .contained {
            VideoPlayer(player: player)
        } else {
            PlayerLayerView(player: player, videoGravity: videoGravity)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var poster: some View {
        if isPosterVisible, let posterURL {
            switch layout {
            case .fitted:
                RemoteImage(
                    url: posterURL,
                    aspectRatio: resolvedAspectRatio,
                    contentMode: .fill
                )
                .allowsHitTesting(false)
            case .contained:
                AsyncImage(url: posterURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    default:
                        Color.black
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
            }
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
        if isMuted {
            MediaAudioSession.prepareSilentVideo()
        }
        player.play()
    }

    @MainActor
    private func measureNaturalAspect() async {
        let asset = AVURLAsset(url: url)
        guard let track = try? await asset.loadTracks(withMediaType: .video).first else { return }
        async let size = track.load(.naturalSize)
        async let transform = track.load(.preferredTransform)
        guard let natural = try? await size,
              let preferred = try? await transform
        else { return }
        let rendered = natural.applying(preferred)
        let width = abs(rendered.width)
        let height = abs(rendered.height)
        guard width > 0, height > 0 else { return }
        measuredAspectRatio = width / height
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

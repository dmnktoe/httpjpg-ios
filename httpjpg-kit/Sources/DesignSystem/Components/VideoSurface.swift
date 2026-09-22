import AVFoundation
import SwiftUI

public struct VideoSurface: View {
    public enum Layout: Sendable {
        /// Inline / lightbox-fitted: keep the CMS (or measured) aspect box.
        case fitted
        /// Fullscreen: expand to the proposed size and cover-fill the frame.
        case filled
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
    /// Refined from the clip's natural size once the asset loads — avoids
    /// pillarboxing when the CMS/poster ratio does not match the file
    /// (web uses intrinsic layout or `object-fit: cover` instead).
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
                VideoPlaybackControls(player: player, showsControls: showsControls)
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

    @ViewBuilder
    private var framedSurface: some View {
        switch layout {
        case .fitted:
            surface
                .aspectRatio(resolvedAspectRatio, contentMode: .fit)
                .frame(maxWidth: .infinity)
        case .filled:
            // Portrait lightbox + landscape clip: fill the screen and crop,
            // same idea as web object-fit cover in a full-bleed stage.
            surface
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var surface: some View {
        PlayerLayerView(player: player, videoGravity: .resizeAspectFill)
            .allowsHitTesting(false)
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
            case .filled:
                // RemoteImage always aspect-fits; fullscreen needs a cover fill.
                AsyncImage(url: posterURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Color.black
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
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

import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

public struct SbVideoView: View {
    private let blok: VideoBlok

    @Environment(\.openURL) private var openURL
    @Environment(\.pageTheme) private var theme
    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.displayScale) private var displayScale
    @Environment(\.chromeAccent) private var accent
    @Environment(\.chromeOnAccent) private var onAccent

    @State private var isLightboxPresented = false

    public init(blok: VideoBlok) {
        self.blok = blok
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            if blok.copyright != nil || blok.copyrightSource != nil, copyrightPosition == .below {
                playerStack
                CopyrightLabel(blok.copyright, source: blok.copyrightSource, position: .below)
            } else {
                playerStack.overlay(alignment: overlayAlignment) {
                    if blok.copyright != nil || blok.copyrightSource != nil {
                        CopyrightLabel(blok.copyright, source: blok.copyrightSource, position: copyrightPosition)
                            .padding(copyrightPosition == .overlay ? 0 : Spacing.s2)
                    }
                }
            }
            if blok.caption?.hasContent == true {
                StoryRichText(blok.caption, size: Typography.Size.xs)
                    .opacity(Opacities.muted)
            }
        }
        .blokSpacing(blok.spacing)
    }

    private var playerStack: some View {
        player
            .overlay(alignment: .topTrailing) {
                if blok.opensLightbox, blok.nativeURL != nil {
                    lightboxTrigger
                        .padding(Spacing.s3)
                }
            }
            .fullScreenCover(isPresented: $isLightboxPresented) {
                if let url = blok.nativeURL {
                    VideoLightboxViewer(
                        url: url,
                        posterURL: posterURL,
                        showsControls: blok.showsControls,
                        autoPlays: true,
                        loops: blok.loops,
                        isMuted: blok.isMuted,
                        aspectRatio: resolvedAspectRatio
                    )
                    .chromeAccent(accent, onAccent: onAccent)
                }
            }
    }

    private var lightboxTrigger: some View {
        Button {
            isLightboxPresented = true
        } label: {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(onAccent ?? .white)
                .frame(width: 34, height: 34)
                .contentShape(Circle())
                .glassBackground(
                    in: .circle,
                    tint: accent?.opacity(0.72) ?? .black.opacity(0.55),
                    interactive: true
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Play the video at full size")
    }

    private var player: AnyView {
        AnyView(playerContent)
    }

    @ViewBuilder
    private var playerContent: some View {
        if let url = blok.nativeURL {
            VideoSurface(
                url: url,
                posterURL: posterURL,
                aspectRatio: resolvedAspectRatio,
                showsControls: blok.showsControls,
                autoPlays: blok.autoPlays,
                loops: blok.loops,
                isMuted: blok.isMuted,
                accessibilityText: blok.poster?.alt
            )
        } else if let source = EmbedVideoSurface.Source(rawValue: blok.source),
                  let urlString = blok.videoURL,
                  EmbedVideoSurface.playerURL(source: source, from: urlString) != nil {
            EmbedVideoSurface(
                source: source,
                urlString: urlString,
                posterURL: posterURL,
                aspectRatio: resolvedAspectRatio ?? PageLayout.mediaAspectRatio,
                showsControls: blok.showsControls,
                autoPlays: blok.autoPlays,
                loops: blok.loops,
                isMuted: blok.isMuted,
                accessibilityText: blok.poster?.alt
            )
        } else if let url = blok.embedURL {
            Button {
                openURL(url)
            } label: {
                handoff(host: url.host ?? blok.source)
            }
            .buttonStyle(.plain)
        }
    }

    private func handoff(host: String) -> some View {
        VStack(spacing: Spacing.s3) {
            MonoText("▸ watch on \(host)", size: Typography.Size.sm)
            MonoText(Ascii.tape, size: Typography.Size.xxs, opacity: Opacities.tape)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(resolvedAspectRatio ?? PageLayout.mediaAspectRatio, contentMode: .fit)
        .overlay(Rectangle().stroke(theme.border, lineWidth: 1))
        .contentShape(Rectangle())
    }

    /// CMS ratio first, then Storyblok asset dimensions, then nil for intrinsic layout.
    private var resolvedAspectRatio: CGFloat? {
        if let cms = blok.aspectRatio { return cms }
        return ImageService.aspectRatio(of: blok.asset?.filename)
    }

    private var copyrightPosition: CopyrightLabel.Position {
        CopyrightLabel.Position(cmsValue: blok.copyrightPosition)
    }

    private var overlayAlignment: Alignment {
        copyrightPosition == .overlay ? .bottom : .bottomTrailing
    }

    private var posterURL: URL? {
        guard let poster = blok.poster else { return nil }
        return URL(string: ImageService.Preset.width(
            poster.filename,
            PageLayout.cardWidth(viewport: viewportWidth),
            scale: displayScale,
            focus: poster.focus ?? ""
        ))
    }
}

private struct VideoLightboxViewer: View {
    let url: URL
    let posterURL: URL?
    let showsControls: Bool
    let autoPlays: Bool
    let loops: Bool
    let isMuted: Bool
    let aspectRatio: CGFloat?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            VideoSurface(
                url: url,
                posterURL: posterURL,
                aspectRatio: aspectRatio,
                showsControls: showsControls,
                autoPlays: autoPlays,
                loops: loops,
                isMuted: isMuted
            )
            .padding(.horizontal, PageLayout.gutter)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button {
                dismiss()
            } label: {
                Text("✕")
                    .font(Typography.mono(Typography.Size.md))
                    .foregroundStyle(Palette.white)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .padding(.trailing, PageLayout.gutter)
            .accessibilityLabel("Close video viewer")
        }
    }
}

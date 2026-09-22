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
                if canOpenLightbox {
                    lightboxTrigger
                        .padding(Spacing.s3)
                }
            }
            .sheet(isPresented: $isLightboxPresented) {
                if let url = blok.nativeURL {
                    VideoLightboxViewer(
                        url: url,
                        posterURL: posterURL,
                        autoPlays: true,
                        loops: blok.loops,
                        isMuted: blok.isMuted,
                        aspectRatio: resolvedAspectRatio,
                        caption: blok.caption,
                        copyright: blok.copyright,
                        copyrightSource: blok.copyrightSource
                    )
                    .chromeAccent(accent, onAccent: onAccent)
                }
            }
    }

    private var canOpenLightbox: Bool {
        blok.opensLightbox && blok.nativeURL != nil
    }

    private var lightboxTrigger: some View {
        Button {
            isLightboxPresented = true
        } label: {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
        }
        .buttonStyle(.glassOrb(
            .overMedia(accent: accent, onAccent: onAccent),
            diameter: PillMetrics.compactOrbDiameter
        ))
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
                aspectRatio: resolvedAspectRatio,
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
        .aspectRatio(resolvedAspectRatio, contentMode: .fit)
        .overlay(Rectangle().stroke(theme.border, lineWidth: 1))
        .contentShape(Rectangle())
    }

    /// Matches web `Video` / `SbVideo` resolution order, then iOS-only poster
    /// fallbacks (AVPlayer has no HTML intrinsic layout). Empty CMS + a CDN
    /// filename without `WxH` used to pass `nil` into `VideoSurface`, which
    /// collapsed the player to zero height (Blence titantron).
    private var resolvedAspectRatio: CGFloat {
        if let cms = blok.aspectRatio { return cms }
        // Web: `resolveMediaAspectRatio(mediaWidth, mediaHeight)` from the asset.
        if let fromAsset = blok.asset?.mediaAspectRatio { return fromAsset }
        if let video = ImageService.aspectRatio(of: blok.asset?.filename) { return video }
        if let fromPoster = blok.poster?.mediaAspectRatio { return fromPoster }
        if let poster = ImageService.aspectRatio(of: blok.poster?.filename) { return poster }
        return PageLayout.mediaAspectRatio
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

/// Popup card for a native video — plain sheet like `PlayerScreen`, dismiss
/// via the system drag indicator (no floating / toolbar close chrome).
private struct VideoLightboxViewer: View {
    let url: URL
    let posterURL: URL?
    let autoPlays: Bool
    let loops: Bool
    let isMuted: Bool
    let aspectRatio: CGFloat
    let caption: RichTextNode?
    let copyright: String?
    let copyrightSource: String?

    private let stageRadius = Radii.xl

    var body: some View {
        VStack(spacing: Spacing.s4) {
            videoStage

            if hasMeta {
                meta
                    .padding(.horizontal, PageLayout.gutter)
            }

            Spacer(minLength: 0)

            MonoText(Ascii.tape, size: Typography.Size.xxs, opacity: Opacities.tape)
                .lineLimit(1)
                .padding(.bottom, Spacing.s6)
        }
        .padding(.top, Spacing.s2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .pageTheme(.dark)
        .pageSurface(.dark)
        .preferredColorScheme(.dark)
        .presentationDragIndicator(.visible)
    }

    private var videoStage: some View {
        VideoSurface(
            url: url,
            posterURL: posterURL,
            aspectRatio: aspectRatio,
            layout: .contained,
            showsControls: true,
            autoPlays: autoPlays,
            loops: loops,
            isMuted: isMuted
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.black, in: RoundedRectangle(cornerRadius: stageRadius, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: stageRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: stageRadius, style: .continuous)
                .strokeBorder(PageTheme.dark.border, lineWidth: 1)
        }
        .padding(.horizontal, PageLayout.gutter)
    }

    private var hasMeta: Bool {
        caption?.hasContent == true
            || copyright != nil
            || copyrightSource != nil
    }

    @ViewBuilder
    private var meta: some View {
        VStack(alignment: .leading, spacing: Spacing.s2) {
            if caption?.hasContent == true {
                StoryRichText(caption, size: Typography.Size.sm)
                    .opacity(Opacities.muted)
            }
            if copyright != nil || copyrightSource != nil {
                CopyrightLabel(copyright, source: copyrightSource, position: .below)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

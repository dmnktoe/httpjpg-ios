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

private struct VideoLightboxViewer: View {
    let url: URL
    let posterURL: URL?
    let showsControls: Bool
    let autoPlays: Bool
    let loops: Bool
    let isMuted: Bool
    let aspectRatio: CGFloat

    @Environment(\.dismiss) private var dismiss
    @Environment(\.chromeAccent) private var accent
    @Environment(\.chromeOnAccent) private var onAccent

    @State private var dragOffset: CGFloat = 0
    @State private var isDismissing = false

    /// Enough travel that a scrub or accidental nudge won't close the stage.
    private let dismissDragThreshold: CGFloat = 120

    var body: some View {
        // Leading close — trailing sits on top of AVKit's volume affordance and
        // above the work-detail share control, so a close tap used to fall
        // through and fire Share once the cover tore down.
        ZStack(alignment: .topLeading) {
            Color.black
                .opacity(backdropOpacity)
                .ignoresSafeArea()

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
            .ignoresSafeArea()
            .offset(y: dragOffset)

            Button {
                close()
            } label: {
                Image(systemName: "xmark")
            }
            // Same chrome glass as the hamburger fallback (`.control`), forced
            // onto the dark theme so the orb stays readable on black — idle
            // untinted glass vanishes against a solid backdrop.
            .buttonStyle(.glassOrb(
                .control(.dark),
                diameter: PillMetrics.orbDiameter
            ))
            .padding(.leading, PageLayout.gutter)
            .padding(.top, Spacing.s2)
            .offset(y: dragOffset)
            .zIndex(1)
            .accessibilityLabel("Close video viewer")
        }
        .simultaneousGesture(swipeDownDismiss)
        .pageTheme(.dark)
        .preferredColorScheme(.dark)
        .chromeAccent(accent, onAccent: onAccent)
    }

    private var backdropOpacity: Double {
        let progress = min(max(Double(dragOffset) / 300, 0), 1)
        return 1 - progress * 0.55
    }

    private var swipeDownDismiss: some Gesture {
        DragGesture(minimumDistance: 24)
            .onChanged { value in
                guard !isDismissing else { return }
                let vertical = value.translation.height
                let horizontal = abs(value.translation.width)
                // Vertical-dominant downward only — leave AVKit scrubbing alone.
                guard vertical > 0, vertical > horizontal else {
                    if dragOffset != 0 { dragOffset = 0 }
                    return
                }
                dragOffset = vertical
            }
            .onEnded { value in
                guard !isDismissing else { return }
                let predicted = value.predictedEndTranslation.height
                if value.translation.height > dismissDragThreshold || predicted > 420 {
                    close()
                } else {
                    withAnimation(Motion.stateChange) { dragOffset = 0 }
                }
            }
    }

    private func close() {
        guard !isDismissing else { return }
        isDismissing = true
        // Yield so the touch ends before the cover tears down — otherwise the
        // same tap can land on the work-detail toolbar underneath.
        Task { @MainActor in
            await Task.yield()
            dismiss()
        }
    }
}

import DesignSystem
import StoryblokCore
import SwiftUI

public struct SbScrollClipImageView: View {
    private let blok: ScrollClipImageBlok

    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.viewportHeight) private var viewportHeight
    @Environment(\.displayScale) private var displayScale
    @Environment(\.openURL) private var openURL
    @Environment(\.storyblokConfiguration) private var configuration
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var progress: CGFloat = 0

    public init(blok: ScrollClipImageBlok) {
        self.blok = blok
    }

    public var body: some View {
        if let asset = blok.image, !asset.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.s2) {
                if let copyright = asset.copyright, !copyright.isEmpty, copyrightPosition == .below {
                    linked(asset)
                    CopyrightLabel(copyright, position: .below)
                } else {
                    linked(asset)
                }
                if blok.caption != nil {
                    StoryRichText(blok.caption, size: Typography.Size.sm)
                        .opacity(Opacities.muted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, blok.spacing.marginBottom == nil ? Spacing.s4 : 0)
            .blokSpacing(blok.spacing)
        }
    }

    private func linked(_ asset: StoryblokAsset) -> AnyView {
        let content = surface(asset)
        guard let link = blok.link, !link.isEmpty,
              let url = link.resolvedURL(siteOrigin: configuration.siteOrigin)
        else { return content }
        return AnyView(
            Button { openURL(url) } label: { content }
                .buttonStyle(.plain)
        )
    }

    /// Returns AnyView on purpose. The reveal's opaque type — a GeometryReader
    /// wrapping a mask and three overlays — is large enough that repeating it
    /// across the link/no-link branches sends type checking superlinear.
    private func surface(_ asset: StoryblokAsset) -> AnyView {
        AnyView(reveal(asset))
    }

    private func reveal(_ asset: StoryblokAsset) -> some View {
        GeometryReader { proxy in
            // Hoisted and annotated on purpose: the same arithmetic written
            // inline inside padding(_:_:), which takes a CGFloat?, sends the
            // type checker into a hang.
            let size: CGSize = proxy.size
            let horizontal: CGFloat = size.width * clipFraction
            let vertical: CGFloat = size.height * clipFraction
            image(asset)
                .frame(width: size.width, height: size.height)
                .scaleEffect(scale)
                .mask {
                    Rectangle()
                        .padding(.horizontal, horizontal)
                        .padding(.vertical, vertical)
                }
                .overlay { brackets(horizontal: horizontal, vertical: vertical) }
                .overlay(alignment: .topTrailing) { progressLabel }
                .overlay(alignment: overlayAlignment) { inlineCopyright(asset) }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .frame(width: configuredWidth)
        // The reveal is driven by how far the frame has travelled up the
        // window, so the whole rect — not just its origin — has to be read.
        .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .global) }) { update(with: $0) }
    }

    private func image(_ asset: StoryblokAsset) -> some View {
        RemoteImage(
            url: URL(string: ImageService.Preset.width(
                asset.filename,
                PageLayout.cardWidth(viewport: viewportWidth),
                scale: displayScale,
                focus: asset.focus ?? ""
            )),
            placeholderURL: URL(string: ImageService.Preset.blur(asset.filename, focus: asset.focus ?? "")),
            aspectRatio: aspectRatio,
            contentMode: .fill,
            accessibilityText: asset.accessibilityText(fallback: blok.alt ?? "")
        )
    }

    @ViewBuilder
    private func brackets(horizontal: CGFloat, vertical: CGFloat) -> some View {
        if blok.showsBrackets {
            let insetX: CGFloat = horizontal + Spacing.s2
            let insetY: CGFloat = vertical + Spacing.s2
            Color.clear
                .overlay(alignment: .topLeading) { bracket("┌") }
                .overlay(alignment: .topTrailing) { bracket("┐") }
                .overlay(alignment: .bottomLeading) { bracket("└") }
                .overlay(alignment: .bottomTrailing) { bracket("┘") }
                .padding(.horizontal, insetX)
                .padding(.vertical, insetY)
                .allowsHitTesting(false)
        }
    }

    private func bracket(_ glyph: String) -> some View {
        MonoText(glyph, size: Typography.Size.lg)
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(Opacities.subtle), radius: 1, y: 1)
    }

    /// Pinning needs sticky positioning, which a plain SwiftUI ScrollView has
    /// no equivalent for, so the pinned layout falls back to the same
    /// entry-driven reveal. The counter still tracks it, as it does on the web.
    @ViewBuilder
    private var progressLabel: some View {
        if blok.isPinned, blok.showsProgress {
            MonoText(
                progressText,
                size: Typography.Size.xs,
                tracking: Typography.Tracking.wider(Typography.Size.xs)
            )
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(Opacities.subtle), radius: 1, y: 1)
            .padding(Spacing.s1)
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func inlineCopyright(_ asset: StoryblokAsset) -> some View {
        if let copyright = asset.copyright, !copyright.isEmpty, copyrightPosition != .below {
            CopyrightLabel(copyright, position: copyrightPosition)
                .padding(copyrightPosition == .overlay ? 0 : Spacing.s2)
        }
    }

    private var progressText: String {
        let step: Int = Int((progress * 99).rounded())
        let padded: String = step < 10 ? "0" + String(step) : String(step)
        return "[ " + padded + " / 99 ]"
    }

    private func update(with rect: CGRect) {
        guard !reduceMotion else {
            // onGeometryChange fires per scroll frame; the reveal is fixed here,
            // so only write once.
            if progress != 1 { progress = 1 }
            return
        }
        // Ported from the web `getEntryProgress`: 0 when the top edge sits at
        // the bottom of the viewport, 1 once the frame is vertically centred.
        let start: CGFloat = viewportHeight
        let end: CGFloat = (viewportHeight - rect.height) / 2
        let travel: CGFloat = start - end
        guard travel > 0 else {
            progress = rect.minY <= end ? 1 : 0
            return
        }
        let consumed: CGFloat = (start - rect.minY) / travel
        progress = Swift.min(Swift.max(consumed, 0), 1)
    }

    private var clipFraction: CGFloat { (1 - progress) * blok.maxClipRatio }

    private var scale: CGFloat { 1 + (1 - progress) * (blok.maxScale - 1) }

    private var aspectRatio: CGFloat { blok.aspectRatio ?? PageLayout.mediaAspectRatio }

    private var configuredWidth: CGFloat? {
        blok.widthFraction.map { PageLayout.cardWidth(viewport: viewportWidth) * $0 }
    }

    private var copyrightPosition: CopyrightLabel.Position {
        CopyrightLabel.Position(cmsValue: blok.copyrightPosition)
    }

    private var overlayAlignment: Alignment {
        copyrightPosition == .overlay ? .bottom : .bottomTrailing
    }
}

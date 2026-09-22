import DesignSystem
import StoryblokCore
import SwiftUI
import Tokens

public struct AssetImage: View {
    private let asset: StoryblokAsset
    private let fallbackAlt: String
    private let aspectRatioOverride: CGFloat?
    private let contentMode: ContentMode
    private let copyrightPosition: CopyrightLabel.Position
    private let blurOnLoad: Bool
    private let opensLightbox: Bool
    private let overlayPattern: String
    private let overlayInset: CGFloat

    @Environment(\.viewportWidth) private var viewportWidth
    @Environment(\.displayScale) private var displayScale
    @Environment(\.chromeAccent) private var accent
    @Environment(\.chromeOnAccent) private var onAccent

    @State private var isZoomed = false
    @State private var isSettling = false

    public init(
        asset: StoryblokAsset,
        fallbackAlt: String = "",
        aspectRatio: CGFloat? = nil,
        contentMode: ContentMode = .fill,
        copyrightPosition: String? = nil,
        blurOnLoad: Bool = true,
        opensLightbox: Bool = true,
        overlayPattern: String = "none",
        overlayInset: CGFloat = 0
    ) {
        self.asset = asset
        self.fallbackAlt = fallbackAlt
        self.aspectRatioOverride = aspectRatio
        self.contentMode = contentMode
        self.copyrightPosition = CopyrightLabel.Position(cmsValue: copyrightPosition)
        self.blurOnLoad = blurOnLoad
        self.opensLightbox = opensLightbox
        self.overlayPattern = overlayPattern
        self.overlayInset = overlayInset
    }

    public var body: some View {
        Group {
            if asset.hasCredit, copyrightPosition == .below {
                VStack(alignment: .leading, spacing: Spacing.s1) {
                    framedImage
                    CopyrightLabel(asset.copyrightText, source: asset.sourceText, position: .below)
                }
            } else {
                framedImage.overlay(alignment: overlayAlignment) {
                    if asset.hasCredit {
                        CopyrightLabel(asset.copyrightText, source: asset.sourceText, position: copyrightPosition)
                            .padding(copyrightPosition == .overlay ? 0 : Spacing.s2)
                    }
                }
            }
        }
        .preference(key: ImageViewerHeldKey.self, value: isZoomed || isSettling)
        .onChange(of: isZoomed) { wasOpen, isOpen in
            guard wasOpen, !isOpen else { return }
            isSettling = true
            Task {
                try? await Task.sleep(for: .milliseconds(400))
                isSettling = false
            }
        }
        .modifier(LightboxTapModifier(
            isEnabled: opensLightbox,
            isPresented: $isZoomed,
            url: zoomURL,
            accessibilityText: asset.accessibilityText(fallback: fallbackAlt),
            animated: asset.isGIF,
            accent: accent,
            onAccent: onAccent
        ))
    }

    private var framedImage: some View {
        image
            .overlay {
                if overlayPattern != "none" {
                    ImageOverlay(
                        pattern: overlayPattern,
                        seed: asset.filename ?? "",
                        inset: overlayInset
                    )
                }
            }
    }

    private var image: some View {
        RemoteImage(
            url: URL(string: ImageService.Preset.width(
                asset.filename,
                PageLayout.cardWidth(viewport: viewportWidth),
                scale: displayScale,
                focus: asset.focus ?? ""
            )),
            placeholderURL: blurOnLoad && !asset.isGIF
                ? URL(string: ImageService.Preset.blur(asset.filename, focus: asset.focus ?? ""))
                : nil,
            aspectRatio: aspectRatioOverride ?? ImageService.aspectRatio(of: asset.filename),
            contentMode: contentMode,
            accessibilityText: asset.accessibilityText(fallback: fallbackAlt),
            animated: asset.isGIF
        )
    }

    private var zoomURL: URL? {
        URL(string: ImageService.Preset.width(
            asset.filename,
            viewportWidth * 2,
            scale: displayScale,
            focus: ""
        ))
    }

    private var overlayAlignment: Alignment {
        copyrightPosition == .overlay ? .bottom : .bottomTrailing
    }
}

private struct LightboxTapModifier: ViewModifier {
    let isEnabled: Bool
    @Binding var isPresented: Bool
    let url: URL?
    let accessibilityText: String
    let animated: Bool
    let accent: Color?
    let onAccent: Color?

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .onTapGesture { isPresented = true }
                .fullScreenCover(isPresented: $isPresented) {
                    ImageZoomViewer(
                        url: url,
                        accessibilityText: accessibilityText,
                        animated: animated
                    )
                    .chromeAccent(accent, onAccent: onAccent)
                }
        } else {
            content
        }
    }
}

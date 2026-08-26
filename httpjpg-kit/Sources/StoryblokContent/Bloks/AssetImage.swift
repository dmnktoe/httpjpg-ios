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
        copyrightPosition: String? = nil
    ) {
        self.asset = asset
        self.fallbackAlt = fallbackAlt
        self.aspectRatioOverride = aspectRatio
        self.contentMode = contentMode
        self.copyrightPosition = CopyrightLabel.Position(cmsValue: copyrightPosition)
    }

    public var body: some View {
        Group {
            if asset.hasCredit, copyrightPosition == .below {
                VStack(alignment: .leading, spacing: Spacing.s1) {
                    image
                    CopyrightLabel(asset.copyrightText, source: asset.sourceText, position: .below)
                }
            } else {
                image.overlay(alignment: overlayAlignment) {
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
        .onTapGesture { isZoomed = true }
        .fullScreenCover(isPresented: $isZoomed) {
            ImageZoomViewer(
                url: URL(string: ImageService.Preset.width(
                    asset.filename,
                    viewportWidth * 2,
                    scale: displayScale,
                    focus: ""
                )),
                accessibilityText: asset.accessibilityText(fallback: fallbackAlt)
            )
            .chromeAccent(accent, onAccent: onAccent)
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
            placeholderURL: URL(string: ImageService.Preset.blur(asset.filename, focus: asset.focus ?? "")),
            aspectRatio: aspectRatioOverride ?? ImageService.aspectRatio(of: asset.filename),
            contentMode: contentMode,
            accessibilityText: asset.accessibilityText(fallback: fallbackAlt)
        )
    }

    private var overlayAlignment: Alignment {
        copyrightPosition == .overlay ? .bottom : .bottomTrailing
    }
}

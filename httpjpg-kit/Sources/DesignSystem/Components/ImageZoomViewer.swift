import SwiftUI
import Tokens

public struct ImageZoomViewer: View {
    private let url: URL?
    private let accessibilityText: String?
    private let animated: Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.chromeAccent) private var accent
    @Environment(\.chromeOnAccent) private var onAccent

    public init(url: URL?, accessibilityText: String? = nil, animated: Bool = false) {
        self.url = url
        self.accessibilityText = accessibilityText
        self.animated = animated
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            ZoomableScrollView {
                zoomedImage
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel(accessibilityText ?? "")
                    .accessibilityHidden(accessibilityText == nil)
            }
            .ignoresSafeArea()

            GlassButton(
                shape: .circle,
                tint: accent,
                labelColor: onAccent ?? Palette.white,
                clear: true,
                controlSize: .regular,
                accessibilityLabel: "Close image viewer"
            ) {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: Typography.Size.md, weight: .semibold))
                    .frame(width: Spacing.s9, height: Spacing.s9)
                    .contentShape(Circle())
            }
            .padding(.leading, PageLayout.gutter)
            .zIndex(1)
        }
    }

    @ViewBuilder
    private var zoomedImage: some View {
        if animated {
            AnimatedGIFView(url: url, contentMode: .fit)
        } else {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure:
                    AsciiArt(Ascii.offline, label: "Image unavailable", size: Typography.Size.xxs, opacity: 0.6)
                        .foregroundStyle(Palette.white)
                default:
                    ProgressView()
                        .tint(Palette.white)
                }
            }
        }
    }
}

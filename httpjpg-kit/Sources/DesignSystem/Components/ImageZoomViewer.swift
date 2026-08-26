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
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            ZoomableScrollView {
                zoomedImage
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel(accessibilityText ?? "")
                    .accessibilityHidden(accessibilityText == nil)
            }
            .ignoresSafeArea()

            Button {
                dismiss()
            } label: {
                Text("✕")
                    .font(Typography.mono(Typography.Size.md))
                    .foregroundStyle(onAccent ?? Palette.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
                    .glassBackground(
                        in: .circle,
                        tint: accent?.opacity(0.72) ?? Palette.black.opacity(0.55),
                        interactive: true
                    )
            }
            .buttonStyle(.plain)
            .padding(.trailing, PageLayout.gutter)
            .accessibilityLabel("Close image viewer")
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

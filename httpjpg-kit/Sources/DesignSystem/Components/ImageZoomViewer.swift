import SwiftUI
import Tokens

public struct ImageZoomViewer: View {
    private static let closeDiameter: CGFloat = Spacing.s9

    private let url: URL?
    private let accessibilityText: String?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.chromeAccent) private var accent
    @Environment(\.chromeOnAccent) private var onAccent

    public init(url: URL?, accessibilityText: String? = nil) {
        self.url = url
        self.accessibilityText = accessibilityText
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            ZoomableScrollView {
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel(accessibilityText ?? "")
                .accessibilityHidden(accessibilityText == nil)
            }
            .ignoresSafeArea()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: Typography.Size.md, weight: .semibold))
                    .foregroundStyle(onAccent ?? Palette.white)
                    .frame(width: Self.closeDiameter, height: Self.closeDiameter)
                    .contentShape(.circle)
                    .glassBackground(
                        in: .circle,
                        tint: accent,
                        interactive: true
                    )
            }
            .buttonStyle(.plain)
            .padding(.leading, PageLayout.gutter)
            .zIndex(1)
            .accessibilityLabel("Close image viewer")
        }
    }
}

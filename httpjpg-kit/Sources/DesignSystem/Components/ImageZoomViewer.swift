import SwiftUI
import Tokens

public struct ImageZoomViewer: View {
    private let url: URL?
    private let accessibilityText: String?

    @Environment(\.dismiss) private var dismiss

    public init(url: URL?, accessibilityText: String? = nil) {
        self.url = url
        self.accessibilityText = accessibilityText
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
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
                Text("✕")
                    .font(Typography.mono(Typography.Size.md))
                    .foregroundStyle(Palette.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
                    .glassBackground(in: .circle, tint: Palette.black.opacity(0.55), interactive: true)
            }
            .buttonStyle(.plain)
            .padding(.trailing, PageLayout.gutter)
            .accessibilityLabel("Close image viewer")
        }
    }
}

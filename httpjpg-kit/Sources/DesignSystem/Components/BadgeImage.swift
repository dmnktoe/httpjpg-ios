import SVGView
import SwiftUI
import UIKit

/// A badge drawn at a fixed height, with the width following the image's own
/// aspect ratio — the same contract as the web `Badge`.
///
/// shields.io serves SVG, which ImageIO cannot decode, so `AsyncImage` is not
/// enough here: the bytes are fetched once and then routed to either the vector
/// or the bitmap renderer.
public struct BadgeImage: View {
    private let url: URL?
    private let accessibilityText: String
    private let height: CGFloat

    @Environment(\.pageTheme) private var theme

    @State private var phase: Phase = .loading

    private enum Phase {
        case loading
        case vector(SVGNode, aspectRatio: CGFloat)
        case bitmap(UIImage)
        case failed
    }

    /// Falls back to a squat badge shape while the real ratio is unknown.
    static let placeholderAspectRatio: CGFloat = 4

    public init(url: URL?, accessibilityText: String, height: CGFloat) {
        self.url = url
        self.accessibilityText = accessibilityText
        self.height = height
    }

    public var body: some View {
        content
            .frame(height: height)
            .accessibilityLabel(accessibilityText)
            .task(id: url) { await load() }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .loading:
            theme.border.opacity(Opacities.dimmed)
                .aspectRatio(Self.placeholderAspectRatio, contentMode: .fit)
        case .vector(let node, let aspectRatio):
            SVGView(svg: node)
                .aspectRatio(aspectRatio, contentMode: .fit)
        case .bitmap(let image):
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        case .failed:
            MonoText(accessibilityText, size: Typography.Size.xxs, opacity: Opacities.muted)
                .lineLimit(1)
                .padding(.horizontal, Spacing.s2)
                .overlay(Rectangle().stroke(theme.border, lineWidth: 1))
        }
    }

    private func load() async {
        guard let url else {
            phase = .failed
            return
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            let mimeType = response.mimeType?.lowercased() ?? ""
            if mimeType.contains("svg") || Self.looksLikeSVG(data) {
                guard let node = SVGParser.parse(data: data) else {
                    phase = .failed
                    return
                }
                phase = .vector(node, aspectRatio: Self.aspectRatio(of: node))
            } else if let image = UIImage(data: data) {
                phase = .bitmap(image)
            } else {
                phase = .failed
            }
        } catch {
            phase = .failed
        }
    }

    /// Some CDNs mislabel SVG as text/plain or octet-stream, so the bytes get
    /// the final say.
    static func looksLikeSVG(_ data: Data) -> Bool {
        guard let head = String(data: data.prefix(512), encoding: .utf8)?.lowercased() else {
            return false
        }
        return head.contains("<svg")
    }

    static func aspectRatio(of node: SVGNode) -> CGFloat {
        let bounds = node.bounds()
        guard bounds.width > 0, bounds.height > 0 else { return placeholderAspectRatio }
        return bounds.width / bounds.height
    }
}

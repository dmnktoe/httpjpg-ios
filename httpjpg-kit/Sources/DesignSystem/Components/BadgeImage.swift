import SVGView
import SwiftUI
import Tokens
import UIKit

public struct BadgeImage: View {
    private let url: URL?
    private let accessibilityText: String
    private let height: CGFloat

    @Environment(\.pageTheme) private var theme

    @State private var phase: Phase = .loading

    private enum Phase {
        case loading
        case shields(ShieldsBadge)
        case vector(SVGNode, aspectRatio: CGFloat)
        case bitmap(UIImage)
        case failed
    }

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
        case .shields(let badge):
            shields(badge)
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

    private func shields(_ badge: ShieldsBadge) -> some View {
        HStack(spacing: 0) {
            ForEach(badge.segments.indices, id: \.self) { index in
                Text(badge.segments[index].text)
                    .font(.system(size: height * 0.55, design: .monospaced))
                    .foregroundStyle(Palette.white)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, height * 0.25)
                    .frame(maxHeight: .infinity)
                    .background(Palette.named(badge.segments[index].color) ?? theme.border)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: height * 0.15))
    }

    private func load() async {
        guard let url else {
            phase = .failed
            return
        }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                phase = .failed
                return
            }
            let mimeType = response.mimeType?.lowercased() ?? ""
            if mimeType.contains("svg") || Self.looksLikeSVG(data) {
                if let badge = ShieldsBadge.parse(data) {
                    phase = .shields(badge)
                    return
                }
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

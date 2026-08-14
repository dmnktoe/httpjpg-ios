import SwiftUI
import Tokens
import UIKit

public struct CopyrightLabel: View {
    public enum Position: String, Sendable {
        case below
        case overlay
        case inlineBlack = "inline-black"
        case inlineWhite = "inline-white"

        public init(cmsValue: String?) {
            self = cmsValue.flatMap(Position.init(rawValue:)) ?? .inlineWhite
        }
    }

    private let text: String?
    private let source: String?
    private let position: Position

    private static let inlineFontSize: CGFloat = 11
    private static let inlineLineHeight: CGFloat = 14

    public init(_ text: String? = nil, source: String? = nil, position: Position = .inlineWhite) {
        self.text = text.flatMap { $0.isEmpty ? nil : $0 }
        self.source = source.flatMap { $0.isEmpty ? nil : $0 }
        self.position = position
    }

    public var body: some View {
        if !lines.isEmpty {
            switch position {
            case .below:
                linesStack(font: Typography.sans(Typography.Size.xs))

            case .overlay:
                linesStack(font: Typography.sans(Typography.Size.sm))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.s4)
                    .background(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .allowsHitTesting(false)

            case .inlineBlack:
                inline(.black)
            case .inlineWhite:
                inline(.white)
            }
        }
    }

    private func linesStack(font: Font) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(lines, id: \.self) { line in
                Text(line)
            }
        }
        .font(font)
        .opacity(Opacities.muted)
    }

    private func inline(_ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(Typography.sans(Self.inlineFontSize))
                    .foregroundStyle(color)
                    .opacity(Opacities.muted)
                    .fixedSize()
            }
        }
        .rotationEffect(.degrees(-90))
        .frame(width: measuredBlockHeight, height: measuredTextWidth)
        .allowsHitTesting(false)
        .accessibilityLabel(accessibilityText)
    }

    private var measuredTextWidth: CGFloat {
        lines.map { line in
            (line as NSString)
                .size(withAttributes: [.font: Typography.uiSans(Self.inlineFontSize)])
                .width
        }
        .max()
        .map { $0.rounded(.up) } ?? 0
    }

    private var measuredBlockHeight: CGFloat {
        Self.inlineLineHeight * CGFloat(max(lines.count, 1))
    }

    private var lines: [String] {
        [text.map { "© \($0)" }, source].compactMap { $0 }
    }

    private var accessibilityText: String {
        [text.map { "Copyright \($0)" }, source].compactMap { $0 }.joined(separator: ", ")
    }
}

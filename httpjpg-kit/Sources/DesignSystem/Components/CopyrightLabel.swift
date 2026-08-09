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

    private let text: String
    private let position: Position

    private static let inlineFontSize: CGFloat = 11
    private static let inlineLineHeight: CGFloat = 14

    public init(_ text: String, position: Position = .inlineWhite) {
        self.text = text
        self.position = position
    }

    public var body: some View {
        switch position {
        case .below:
            Text(label)
                .font(Typography.sans(Typography.Size.xs))
                .opacity(Opacities.muted)

        case .overlay:
            Text(label)
                .font(Typography.sans(Typography.Size.sm))
                .foregroundStyle(.white)
                .opacity(Opacities.muted)
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

    private func inline(_ color: Color) -> some View {
        Text(label)
            .font(Typography.sans(Self.inlineFontSize))
            .foregroundStyle(color)
            .opacity(Opacities.muted)
            .fixedSize()
            .rotationEffect(.degrees(-90))
            .frame(width: Self.inlineLineHeight, height: measuredTextWidth)
            .allowsHitTesting(false)
            .accessibilityLabel("Copyright \(text)")
    }

    private var measuredTextWidth: CGFloat {
        (label as NSString)
            .size(withAttributes: [.font: Typography.uiSans(Self.inlineFontSize)])
            .width
            .rounded(.up)
    }

    private var label: String { "© \(text)" }
}

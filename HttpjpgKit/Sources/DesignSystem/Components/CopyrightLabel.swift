import SwiftUI
import UIKit

/// Photo credit — the Swift port of `@httpjpg/ui`'s `<CopyrightLabel>`.
///
/// The web's four positions come across: the two `inline` variants run
/// *vertically* up the image's right edge, `overlay` is a gradient strip along
/// the bottom, `below` is an ordinary line for the caller to place under the
/// image. The © is prepended here, same as on the web.
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

    /// Line height of the inline variant's face, used to pull the rotated
    /// strip back inside the image edge.
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

    /// The vertical strip, reading bottom-to-top like the web's
    /// `writing-mode: vertical-rl` + `rotate(180deg)`.
    ///
    /// SwiftUI has no writing mode, so this is plain text rotated −90° about
    /// its centre — and because rotation moves pixels but not the layout
    /// frame, the view is then given an explicit frame of the *rotated*
    /// dimensions (line height wide, text width tall). That measured frame is
    /// what lets a plain `.bottomTrailing` overlay alignment pin it to the
    /// corner; without it the alignment would place the unrotated box.
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

    /// The unrotated text width, measured with the same face the view sets, so
    /// the frame swap above is exact rather than guessed.
    private var measuredTextWidth: CGFloat {
        (label as NSString)
            .size(withAttributes: [.font: Typography.uiSans(Self.inlineFontSize)])
            .width
            .rounded(.up)
    }

    private var label: String { "© \(text)" }
}

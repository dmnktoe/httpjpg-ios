import SwiftUI
import UIKit

public enum Typography {
    public enum Family {
        public static var headline: String {
            FontRegistry.resolve(FontRegistry.headlineCandidates, fallback: "HelveticaNeue-CondensedBlack")
        }

        public static var headlineBold: String { headline }

        public static var sans: String {
            FontRegistry.resolve(FontRegistry.sansCandidates, fallback: "Helvetica")
        }

        public static var sansBold: String {
            FontRegistry.resolve(FontRegistry.sansBoldCandidates, fallback: "Helvetica-Bold")
        }

        public static var accent: String {
            FontRegistry.resolve(FontRegistry.accentCandidates, fallback: "SnellRoundhand-Black")
        }
    }

    public enum Size {
        public static let xxs: CGFloat = 10

        public static let xs: CGFloat = 11

        public static let sm: CGFloat = 12

        public static let md: CGFloat = 14

        public static let base: CGFloat = 16

        public static let lg: CGFloat = 16

        public static let xl: CGFloat = 18
    }

    public enum Tracking {
        public static func tighter(_ size: CGFloat) -> CGFloat { size * -0.05 }
        public static func tight(_ size: CGFloat) -> CGFloat { size * -0.025 }
        public static func normal(_ size: CGFloat) -> CGFloat { 0 }
        public static func wide(_ size: CGFloat) -> CGFloat { size * 0.025 }
        public static func wider(_ size: CGFloat) -> CGFloat { size * 0.05 }
        public static func widest(_ size: CGFloat) -> CGFloat { size * 0.1 }
    }

    public static func headline(_ size: CGFloat, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        .custom(Family.headline, size: size, relativeTo: style)
    }

    public static func headlineBold(_ size: CGFloat, relativeTo style: Font.TextStyle = .title) -> Font {
        .custom(Family.headlineBold, size: size, relativeTo: style)
    }

    public static func sans(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(Family.sans, size: size, relativeTo: style)
    }

    public static func sansBold(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(Family.sansBold, size: size, relativeTo: style)
    }

    public static func accent(_ size: CGFloat, relativeTo style: Font.TextStyle = .title) -> Font {
        .custom(Family.accent, size: size, relativeTo: style)
    }

    public static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let scaled = UIFontMetrics(forTextStyle: .footnote).scaledValue(for: size)
        return .system(size: min(scaled, size * monoScaleCap), weight: weight, design: .monospaced)
    }

    static let monoScaleCap: CGFloat = 1.6

    public static func uiSans(_ size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let name = weight.rawValue >= UIFont.Weight.semibold.rawValue ? Family.sansBold : Family.sans
        let font = UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: weight)
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
    }

    public static func uiHeadline(_ size: CGFloat) -> UIFont {
        let font = UIFont(name: Family.headline, size: size)
            ?? .systemFont(ofSize: size, weight: .black)
        return UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: font)
    }

    public static func uiMono(_ size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let scaled = min(
            UIFontMetrics(forTextStyle: .footnote).scaledValue(for: size),
            size * monoScaleCap
        )
        return .monospacedSystemFont(ofSize: scaled, weight: weight)
    }

    public static func clamp(
        min minimum: CGFloat,
        slope: CGFloat,
        intercept: CGFloat,
        max maximum: CGFloat,
        width: CGFloat
    ) -> CGFloat {
        Swift.min(Swift.max(slope * width + intercept, minimum), maximum)
    }
}

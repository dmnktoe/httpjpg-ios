import SwiftUI
import UIKit

/// Typography ported from `packages/tokens/src/typography.ts`.
///
/// The web font stacks don't exist verbatim on iOS, so each family resolves at
/// runtime through the same kind of ordered stack a browser walks — see
/// ``FontRegistry``:
///
/// | Token      | Web stack                              | iOS resolution                       |
/// | ---------- | -------------------------------------- | ------------------------------------ |
/// | `headline` | Impact, Haettenschweiler, Arial Narrow | Impact → **Anton** (bundled) → HelveticaNeue-CondensedBlack |
/// | `sans`     | Arial, Helvetica                       | Helvetica → Arial                    |
/// | `accent`   | Trattatello, Snell Roundhand, …        | Trattatello → SnellRoundhand-Black   |
/// | `mono`     | ui-monospace, SF Mono, Menlo           | SF Mono (`.monospaced`)              |
///
/// Every family goes through `Font.custom(_:size:relativeTo:)` so Dynamic Type
/// still scales the app.
public enum Typography {
    public enum Family {
        /// Impact if you bundle it, otherwise Anton — see ``FontRegistry``.
        public static var headline: String {
            FontRegistry.resolve(FontRegistry.headlineCandidates, fallback: "HelveticaNeue-CondensedBlack")
        }

        /// Anton ships in a single weight, so the "bold" headline is the same
        /// face; only the system fallback has a lighter cut.
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

    /// Font sizes from the `fontSize` token family (`rem` → points, 1rem = 16pt).
    public enum Size {
        /// `0.65rem` — the ⌘ρτ marker on work cards.
        public static let xxs: CGFloat = 10
        /// `0.7rem` — tag chips.
        public static let xs: CGFloat = 11
        /// `0.75rem` — the web's default body size.
        public static let sm: CGFloat = 12
        /// `0.875rem`
        public static let md: CGFloat = 14
        /// `1rem`
        public static let base: CGFloat = 16
        /// `1rem`
        public static let lg: CGFloat = 16
        /// `1.125rem`
        public static let xl: CGFloat = 18
    }

    /// `letterSpacing` tokens, expressed as points at a given font size.
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
        .system(size: size, weight: weight, design: .monospaced)
    }

    // MARK: - UIKit interop
    //
    // `MarqueeLabel` is a `UILabel` subclass, so the marquee needs the same
    // token scale expressed as `UIFont`. Each helper falls back to the system
    // face when a name is unavailable, matching SwiftUI's behaviour.

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
        UIFontMetrics(forTextStyle: .footnote)
            .scaledFont(for: .monospacedSystemFont(ofSize: size, weight: weight))
    }

    /// The CSS `clamp()` the web headline recipe uses, evaluated against a
    /// concrete viewport width instead of the browser's `vw` unit.
    ///
    /// `clamp(2.25rem, 5vw + 1rem, 3.75rem)` becomes
    /// `clamp(min: 36, slope: 0.05, intercept: 16, max: 60, width: …)`.
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

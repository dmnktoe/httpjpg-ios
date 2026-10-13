import CoreGraphics
import Foundation

public enum ResponsiveWidth {
    public static let tabletBreakpoint: CGFloat = 768
    public static let desktopBreakpoint: CGFloat = 1024

    public static func fraction(
        base: String?,
        tablet: String?,
        desktop: String?,
        viewportWidth: CGFloat
    ) -> CGFloat? {
        let chosen = choice(base: base, tablet: tablet, desktop: desktop, viewportWidth: viewportWidth)
        return parsePercent(chosen)
    }

    public static func choice(
        base: String?,
        tablet: String?,
        desktop: String?,
        viewportWidth: CGFloat
    ) -> String? {
        let tabletResolved = nonEmpty(tablet) ?? nonEmpty(base)
        let desktopResolved = nonEmpty(desktop) ?? nonEmpty(tablet) ?? nonEmpty(base)
        if viewportWidth >= desktopBreakpoint {
            return desktopResolved
        }
        if viewportWidth >= tabletBreakpoint {
            return tabletResolved
        }
        return nonEmpty(base)
    }

    public static func parsePercent(_ raw: String?) -> CGFloat? {
        guard let raw, raw.hasSuffix("%"),
              let value = Double(raw.dropLast()),
              value > 0, value < 100
        else { return nil }
        return CGFloat(value) / 100
    }

    private static func nonEmpty(_ raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        return raw
    }
}

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
        let chosen: String?
        if viewportWidth >= desktopBreakpoint, let desktop, !desktop.isEmpty {
            chosen = desktop
        } else if viewportWidth >= tabletBreakpoint, let tablet, !tablet.isEmpty {
            chosen = tablet
        } else {
            chosen = base
        }
        return parsePercent(chosen)
    }

    /// `nil` for a full-width value: 100% is the layout default, not a constraint.
    public static func parsePercent(_ raw: String?) -> CGFloat? {
        guard let raw, raw.hasSuffix("%"),
              let value = Double(raw.dropLast()),
              value > 0, value < 100
        else { return nil }
        return CGFloat(value) / 100
    }
}

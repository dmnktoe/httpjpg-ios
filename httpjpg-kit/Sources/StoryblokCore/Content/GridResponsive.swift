import CoreGraphics
import Foundation

public enum GridColumnSpan: Hashable, Sendable {
    case columns(Int)
    case full
}

public enum GridResponsive {
    public static let autoColumnMinWidth: CGFloat = 200

    public static func columnCount(
        base: String?,
        tablet: String?,
        desktop: String?,
        viewportWidth: CGFloat,
        layoutWidth: CGFloat,
        columnGap: CGFloat
    ) -> Int {
        let raw = ResponsiveWidth.choice(base: base, tablet: tablet, desktop: desktop, viewportWidth: viewportWidth)
        return parseColumnCount(raw, layoutWidth: layoutWidth, columnGap: columnGap)
    }

    public static func parseColumnCount(_ raw: String?, layoutWidth: CGFloat, columnGap: CGFloat) -> Int {
        guard let raw, !raw.isEmpty else { return 1 }
        if raw == "auto" {
            // `repeat(auto-fit, minmax(200px, 1fr))`: as many 200pt tracks as fit, gaps included.
            let fitted = Int(((layoutWidth + columnGap) / (autoColumnMinWidth + columnGap)).rounded(.down))
            return max(fitted, 1)
        }
        if let value = Int(raw) {
            return min(max(value, 1), 12)
        }
        return 1
    }

    public static func parseSpan(_ raw: String?) -> GridColumnSpan {
        guard let raw, !raw.isEmpty else { return .columns(1) }
        if raw == "full" { return .full }
        if let value = Int(raw), value >= 1, value <= 12 {
            return .columns(value)
        }
        return .columns(1)
    }

    public static func resolvedSpan(
        base: String?,
        tablet: String?,
        desktop: String?,
        viewportWidth: CGFloat
    ) -> GridColumnSpan {
        let raw = ResponsiveWidth.choice(base: base, tablet: tablet, desktop: desktop, viewportWidth: viewportWidth)
        return parseSpan(raw)
    }

    public static func isHidden(
        viewportWidth: CGFloat,
        hiddenBase: Bool,
        hiddenMd: Bool,
        hiddenLg: Bool
    ) -> Bool {
        // Each breakpoint's flag stands alone: the web pairs every `display: none`
        // with a `display: block` at the next breakpoint up.
        if viewportWidth >= ResponsiveWidth.desktopBreakpoint { return hiddenLg }
        if viewportWidth >= ResponsiveWidth.tabletBreakpoint { return hiddenMd }
        return hiddenBase
    }
}

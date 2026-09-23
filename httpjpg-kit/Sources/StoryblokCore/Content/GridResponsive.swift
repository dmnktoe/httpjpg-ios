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
        layoutWidth: CGFloat
    ) -> Int {
        let raw = ResponsiveWidth.choice(base: base, tablet: tablet, desktop: desktop, viewportWidth: viewportWidth)
        return parseColumnCount(raw, layoutWidth: layoutWidth)
    }

    public static func parseColumnCount(_ raw: String?, layoutWidth: CGFloat) -> Int {
        guard let raw, !raw.isEmpty else { return 1 }
        if raw == "auto" {
            let fitted = Int(ceil(layoutWidth / autoColumnMinWidth))
            return min(max(fitted, 1), 12)
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
        if viewportWidth >= ResponsiveWidth.desktopBreakpoint {
            if hiddenLg { return true }
            if hiddenMd, !hiddenLg { return false }
            return false
        }
        if viewportWidth >= ResponsiveWidth.tabletBreakpoint {
            if hiddenMd { return true }
            if hiddenBase, !hiddenMd { return false }
            return false
        }
        return hiddenBase
    }
}

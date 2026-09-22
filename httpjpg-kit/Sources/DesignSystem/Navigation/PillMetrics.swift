import CoreGraphics
import Tokens

/// Every number the pill and orb styles use. One table so the tab bar, the
/// filter and the detail-page toolbar stay dimensionally in step.
public enum PillMetrics {
    /// Cap height the label is pinned to, so pills in a row line up even when
    /// one of them scales its text down.
    public static let labelHeight: CGFloat = Spacing.s4

    public static let horizontalPadding: CGFloat = Spacing.s4

    public static let verticalPadding: CGFloat = Spacing.s3

    public static let compactHorizontalPadding: CGFloat = Spacing.s3

    public static let compactVerticalPadding: CGFloat = Spacing.s2

    /// Round controls — header buttons, carousel arrows — are one size, big
    /// enough to fill the navigation bar rather than float a small disc in it.
    public static let orbDiameter: CGFloat = Spacing.s10

    /// Round controls laid over media, where the artwork carries the frame and
    /// a bar-height disc would cover too much of it.
    public static let compactOrbDiameter: CGFloat = Spacing.s9

    public static let hairline: CGFloat = 1

    /// Glass already dips under a press; the scale is there for the fallback
    /// path, which otherwise gives no feedback at all.
    public static let pressedScale: CGFloat = 0.96

    /// Smallest the label may shrink before it truncates instead.
    public static let labelScaleFloor: CGFloat = 0.7
}

import CoreGraphics
import Tokens

public enum PillMetrics {
    public static let labelHeight: CGFloat = Spacing.s4

    public static let horizontalPadding: CGFloat = Spacing.s4

    public static let verticalPadding: CGFloat = Spacing.s3

    public static let compactHorizontalPadding: CGFloat = Spacing.s3

    public static let compactVerticalPadding: CGFloat = Spacing.s2

    public static let orbDiameter: CGFloat = Spacing.s10

    public static let compactOrbDiameter: CGFloat = Spacing.s9

    public static let hairline: CGFloat = 1

    public static let pressedScale: CGFloat = 0.96

    public static let labelScaleFloor: CGFloat = 0.7

    // Inset between a tab bar's glass and its selection, taken out of the
    // segment padding so the bar stays as tall as a lone pill.
    public static let tabInset: CGFloat = Spacing.s1

    public static let scrubStretch: CGFloat = 1.04

    public static let tapSlop: CGFloat = Spacing.s2
}

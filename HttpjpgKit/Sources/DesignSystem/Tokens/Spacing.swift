import CoreGraphics

/// Spacing scale ported from `packages/tokens/src/spacing.ts`.
///
/// The web scale is expressed in `rem`; here `1rem == 16pt`, which keeps the
/// 4pt rhythm iOS layout expects and the web's step names identical.
public enum Spacing {
    public static let s0: CGFloat = 0
    public static let s1: CGFloat = 4
    public static let s2: CGFloat = 8
    public static let s3: CGFloat = 12
    public static let s4: CGFloat = 16
    public static let s5: CGFloat = 20
    public static let s6: CGFloat = 24
    public static let s7: CGFloat = 28
    public static let s8: CGFloat = 32
    public static let s9: CGFloat = 36
    public static let s10: CGFloat = 40
    public static let s11: CGFloat = 44
    public static let s12: CGFloat = 48
    public static let s14: CGFloat = 56
    public static let s16: CGFloat = 64
    public static let s20: CGFloat = 80
    public static let s24: CGFloat = 96
    public static let s28: CGFloat = 112
    public static let s32: CGFloat = 128

    /// Resolves a Storyblok `spacing-options` datasource value (`"4"`, `"12"`, …).
    public static func named(_ value: String?) -> CGFloat? {
        guard let value, let key = Int(value) else { return nil }
        return step(key)
    }

    /// Resolves a numeric Panda spacing key to points.
    public static func step(_ key: Int) -> CGFloat? {
        switch key {
        case 0: return s0
        case 1: return s1
        case 2: return s2
        case 3: return s3
        case 4: return s4
        case 5: return s5
        case 6: return s6
        case 7: return s7
        case 8: return s8
        case 9: return s9
        case 10: return s10
        case 11: return s11
        case 12: return s12
        case 14: return s14
        case 16: return s16
        case 20: return s20
        case 24: return s24
        case 28: return s28
        case 32: return s32
        default: return nil
        }
    }
}

/// Corner radii from `packages/tokens/src/border-radius.ts`.
///
/// The portfolio is brutalist: almost everything uses ``none``. The rest of the
/// scale exists so CMS-driven values keep resolving.
public enum Radii {
    public static let none: CGFloat = 0
    public static let sm: CGFloat = 2
    public static let base: CGFloat = 4
    public static let md: CGFloat = 6
    public static let lg: CGFloat = 8
    public static let xl: CGFloat = 12
    public static let xxl: CGFloat = 16
    public static let xxxl: CGFloat = 24
    public static let full: CGFloat = 9999
}

/// Opacity steps used by the ASCII furniture and muted meta rows.
public enum Opacities {
    public static let tape: Double = 0.25
    public static let dimmed: Double = 0.3
    public static let subtle: Double = 0.5
    public static let muted: Double = 0.7
}

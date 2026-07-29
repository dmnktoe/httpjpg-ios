import SwiftUI

public struct ColorRamp: Sendable {
    public let s50: Color
    public let s100: Color
    public let s200: Color
    public let s300: Color
    public let s400: Color
    public let s500: Color
    public let s600: Color
    public let s700: Color
    public let s800: Color
    public let s900: Color
    public let s950: Color

    init(
        _ s50: UInt32,
        _ s100: UInt32,
        _ s200: UInt32,
        _ s300: UInt32,
        _ s400: UInt32,
        _ s500: UInt32,
        _ s600: UInt32,
        _ s700: UInt32,
        _ s800: UInt32,
        _ s900: UInt32,
        _ s950: UInt32
    ) {
        self.s50 = Color(hex: s50)
        self.s100 = Color(hex: s100)
        self.s200 = Color(hex: s200)
        self.s300 = Color(hex: s300)
        self.s400 = Color(hex: s400)
        self.s500 = Color(hex: s500)
        self.s600 = Color(hex: s600)
        self.s700 = Color(hex: s700)
        self.s800 = Color(hex: s800)
        self.s900 = Color(hex: s900)
        self.s950 = Color(hex: s950)
    }

    public func step(_ key: Int) -> Color? {
        switch key {
        case 50: return s50
        case 100: return s100
        case 200: return s200
        case 300: return s300
        case 400: return s400
        case 500: return s500
        case 600: return s600
        case 700: return s700
        case 800: return s800
        case 900: return s900
        case 950: return s950
        default: return nil
        }
    }
}

public enum Palette {
    public static let black = Color(hex: 0x000000)
    public static let white = Color(hex: 0xFFFFFF)

    public static let neutral = ColorRamp(
        0xFAFAFA, 0xF5F5F5, 0xE5E5E5, 0xD4D4D4, 0xA3A3A3, 0x737373,
        0x525252, 0x404040, 0x262626, 0x171717, 0x0A0A0A
    )

    public static let primary = ColorRamp(
        0xEFF6FF, 0xDBEAFE, 0xBFDBFE, 0x93C5FD, 0x60A5FA, 0x3B82F6,
        0x2563EB, 0x1D4ED8, 0x1E40AF, 0x1E3A8A, 0x172554
    )

    public static let accent = ColorRamp(
        0xF7FEE7, 0xECFCCB, 0xD9F99D, 0xBEF264, 0xA3E635, 0x84CC16,
        0x65A30D, 0x4D7C0F, 0x3F6212, 0x365314, 0x1A2E05
    )

    public static let success = ColorRamp(
        0xF0FDF4, 0xDCFCE7, 0xBBF7D0, 0x86EFAC, 0x4ADE80, 0x22C55E,
        0x16A34A, 0x15803D, 0x166534, 0x14532D, 0x052E16
    )

    public static let warning = ColorRamp(
        0xFFFBEB, 0xFEF3C7, 0xFDE68A, 0xFCD34D, 0xFBBF24, 0xF59E0B,
        0xD97706, 0xB45309, 0x92400E, 0x78350F, 0x451A03
    )

    public static let danger = ColorRamp(
        0xFEF2F2, 0xFEE2E2, 0xFECACA, 0xFCA5A5, 0xF87171, 0xEF4444,
        0xDC2626, 0xB91C1C, 0x991B1B, 0x7F1D1D, 0x450A0A
    )

    public static func named(_ value: String?) -> Color? {
        guard let value, !value.isEmpty else { return nil }
        switch value {
        case "black": return black
        case "white": return white
        default: break
        }
        if let hex = hexValue(value) {
            return Color(hex: hex)
        }
        let parts = value.split(separator: ".")
        guard parts.count == 2, let step = Int(parts[1]) else { return nil }
        switch parts[0] {
        case "neutral": return neutral.step(step)
        case "primary": return primary.step(step)
        case "accent": return accent.step(step)
        case "success": return success.step(step)
        case "warning": return warning.step(step)
        case "danger": return danger.step(step)
        default: return nil
        }
    }

    static func hexValue(_ value: String) -> UInt32? {
        var digits = Substring(value)
        if digits.hasPrefix("#") {
            digits = digits.dropFirst()
        }
        guard digits.count == 6 || digits.count == 3 else { return nil }
        guard digits.allSatisfy(\.isHexDigit) else { return nil }

        let expanded = digits.count == 3
            ? digits.map { String(repeating: $0, count: 2) }.joined()
            : String(digits)
        return UInt32(expanded, radix: 16)
    }
}

public extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

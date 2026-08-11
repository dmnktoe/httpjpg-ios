import Foundation

public enum ListMarker {
    public static func bullet(style: String) -> String {
        switch style {
        case "circle": return "◦"
        case "square": return "▪"
        case "none": return ""
        default: return "•"
        }
    }

    public static func ordinal(_ position: Int, style: String) -> String {
        switch style {
        case "lower-alpha": return alpha(position).lowercased()
        case "upper-alpha": return alpha(position)
        case "lower-roman": return roman(position).lowercased()
        case "upper-roman": return roman(position)
        default: return String(position)
        }
    }

    static func alpha(_ position: Int) -> String {
        guard position > 0 else { return "" }
        var remaining = position
        var result = ""
        while remaining > 0 {
            let index = (remaining - 1) % 26
            result = String(UnicodeScalar(UInt8(65 + index))) + result
            remaining = (remaining - 1) / 26
        }
        return result
    }

    static func roman(_ position: Int) -> String {
        guard position > 0, position < 4000 else { return String(position) }
        var remaining = position
        var result = ""
        for (amount, symbol) in numerals where remaining >= amount {
            while remaining >= amount {
                result += symbol
                remaining -= amount
            }
        }
        return result
    }

    private static let numerals: [(Int, String)] = [
        (1000, "M"), (900, "CM"), (500, "D"), (400, "CD"),
        (100, "C"), (90, "XC"), (50, "L"), (40, "XL"),
        (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I"),
    ]
}

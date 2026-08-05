import CoreGraphics
import Foundation

/// The CMS stores a few sizes as free-form CSS lengths (the icon blok asks for
/// "32px or 2rem"), so they arrive as strings that have to become points.
enum CSSLength {
    static let rootFontSize: CGFloat = 16

    static func points(_ raw: String?) -> CGFloat? {
        guard let raw else { return nil }
        let value = raw.trimmingCharacters(in: .whitespaces).lowercased()
        guard !value.isEmpty else { return nil }

        // "rem" has to be tested before "em", which is a suffix of it.
        let units: [(String, CGFloat)] = [
            ("px", 1), ("pt", 1), ("rem", rootFontSize), ("em", rootFontSize),
        ]
        for (suffix, scale) in units {
            guard value.hasSuffix(suffix) else { continue }
            guard let number = Double(value.dropLast(suffix.count)) else { return nil }
            return CGFloat(number) * scale
        }
        return Double(value).map(CGFloat.init)
    }
}
